class Admin::KanjisController < ApplicationController
  # ================= CẤU HÌNH LOCALHOST =================
  BASE_URL = "#{Rails.configuration.x.api_base_url}/api/v1/kanjis"

  API_HEADERS = {
    'Content-Type' => 'application/json'
  }

  skip_before_action :verify_authenticity_token, only: [:approve, :reject]

  # ================= INDEX =================
  def index
    @page_title = "Quản lý Kanji"

    # 1. Xử lý trang (Chuyển từ 1-based của Ruby sang 0-based của Java)
    @current_page = (params[:page] || 1).to_i
    java_page = @current_page - 1
    java_page = 0 if java_page < 0

    java_params = { page: java_page }

    # 2. Xử lý từ khóa tìm kiếm
    if params[:keyword].present?
      k = params[:keyword].strip
      java_params[:search] = k # Khớp với @RequestParam(name = "search") bên Java
    end

    # 3. Xử lý trạng thái và tính chất Active
    if params[:status].present?
      java_params[:status] = params[:status]
      # Tự động map is_active để Java lọc chính xác bản gốc hoặc bản nháp
      java_params[:is_active] = (params[:status] == 'ACTIVE') if ['ACTIVE', 'HIDDEN'].include?(params[:status])
    end
    if params[:created_at].present?
      java_params[:created_at] = params[:created_at]
    end
    begin
      response = HTTParty.get(BASE_URL, query: java_params, headers: API_HEADERS, verify: false)

      if response.success?
        body = JSON.parse(response.body)
        # Bóc tách theo cấu trúc: ApiResponse -> data (Map) -> kanjis (Array)
        result_metadata = body["data"] || {}

        if result_metadata.is_a?(Hash)
          @kanjis = result_metadata["kanjis"] || []
          @total_pages = result_metadata["totalPages"] || 1
          @total_elements = result_metadata["totalElements"] || 0
        else
          # Trường hợp dự phòng nếu Java chỉ trả về List đơn thuần
          @kanjis = result_metadata
          @total_pages = 1
        end
      else
        @kanjis = []
        @total_pages = 1
        @total_elements = 0
        flash.now[:alert] = "Backend trả về lỗi: #{response.code}"
      end
    rescue => e
      @kanjis = []
      @total_pages = 1
      @total_elements = 0
      flash.now[:alert] = "Lỗi kết nối Server Java: #{e.message}"
    end
  end

  # ================= SHOW =================
  def show
    # 1. Gọi API lấy chi tiết bản ghi
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      json_body = JSON.parse(response.body)
      # [FIX]: Đảm bảo @kanji là một Hash (đối tượng đơn lẻ)
      @kanji = json_body["data"].is_a?(Array) ? json_body["data"].first : (json_body["data"] || {})

      # =================================================================================
      # NHÓM 1: CHẾ ĐỘ DUYỆT BÀI (REVIEW) - Dành cho PENDING, REJECTED, APPROVED
      # =================================================================================
      if ['PENDING', 'REJECTED', 'APPROVED'].include?(@kanji['status']) && @kanji['is_active'] == false
        @pending_kanji = @kanji

        check_res = HTTParty.get(BASE_URL, query: { kanji: @pending_kanji['kanji'] }, headers: API_HEADERS, verify: false)

        # [FIX QUAN TRỌNG]: Phải dùng .dig("data", "kanjis") để lấy mảng, né lỗi String into Integer
        if check_res.success?
          json_check = JSON.parse(check_res.body)
          existing_list = json_check.dig("data", "kanjis") || []
        else
          existing_list = []
        end

        # Tìm bản ghi Master (ACTIVE/HIDDEN). Lệnh .find giờ sẽ chạy đúng trên Mảng.
        @master_kanji = existing_list.find { |k| ['ACTIVE', 'HIDDEN'].include?(k['status']) }

        if @master_kanji.present?
          @form_data = @master_kanji
          @lock_core_fields = true
          flash.now[:warning] = "Chữ này đã tồn tại (#{@master_kanji['status']}). Form hiển thị dữ liệu GỐC."
        else
          @form_data = @pending_kanji
          @lock_core_fields = false
          flash.now[:info] = "Chữ mới hoàn toàn. Form hiển thị dữ liệu ĐÓNG GÓP."
        end

        render :review

        # =================================================================================
        # NHÓM 2: CHẾ ĐỘ XEM CHI TIẾT (SHOW) - Dành cho bản Gốc (ACTIVE/HIDDEN)
        # =================================================================================
      else
        contrib_res = HTTParty.get("#{BASE_URL}/contributions", query: { kanji: @kanji['kanji'] }, headers: API_HEADERS, verify: false)

        # [FIX]: Bóc tách tương tự cho phần lịch sử đóng góp
        if contrib_res.success?
          json_contrib = JSON.parse(contrib_res.body)
          @contributions = json_contrib.dig("data", "kanjis") || json_contrib["data"] || []
        else
          @contributions = []
        end

        render :show
      end

    else
      redirect_to admin_kanjis_path, alert: "Không tìm thấy dữ liệu (API Error: #{response.code})."
    end
  rescue => e
    # In lỗi ra Terminal Ubuntu để bạn dễ kiểm soát
    puts ">>> LỖI TẠI SHOW/REVIEW: #{e.message}"
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối hệ thống: #{e.message}"
  end
  # ================= NEW =================
  def new
    @kanji = {}
    @errors = {}
    @form_mode = :new
  end

  # ================= CREATE =================
  def create
    payload = map_to_java_dto(get_safe_params)
    payload["status"] = "ACTIVE"
    payload["is_active"] = true

    response = HTTParty.post(BASE_URL, body: payload.to_json, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path, notice: "Tạo Kanji thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      @errors = parsed['errors'] || {}
      flash.now[:alert] = parsed['message'] || "Tạo thất bại"
      @kanji = payload
      render :new
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối: #{e.message}"
  end

  # ================= EDIT =================
  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      data = JSON.parse(response.body)["data"]
      @kanji = data || {}
      @form_mode = :edit
    else
      redirect_to admin_kanjis_path, alert: "Không lấy được dữ liệu Kanji ID: #{params[:id]}"
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối: #{e.message}"
  end

  # ================= UPDATE =================
  def update
    payload = map_to_java_dto(get_safe_params)

    response = HTTParty.put("#{BASE_URL}/#{params[:id]}", body: payload.to_json, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path, notice: "Cập nhật thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      @errors = parsed['errors'] || {}
      flash.now[:alert] = parsed['message'] || "Cập nhật thất bại"
      @kanji = payload
      @kanji['id'] = params[:id]
      render :edit
    end
  end

  # ================= DESTROY =================
  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path, notice: "Đã xóa Kanji thành công!", status: :see_other
    else
      error_msg = JSON.parse(response.body)["message"] rescue response.code
      redirect_to admin_kanjis_path, alert: "Không thể xóa: #{error_msg}"
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi hệ thống: #{e.message}"
  end

  # ================= APPROVE (DUYỆT BÀI) =================

  # app/controllers/admin/kanjis_controller.rb

  # app/controllers/admin/kanjis_controller.rb

  def approve
    kanji_id = params[:id]

    # 1. Lấy thông tin bản ghi PENDING (Đóng góp)
    resp_pending = HTTParty.get("#{BASE_URL}/#{kanji_id}", headers: API_HEADERS, verify: false)

    if resp_pending.success?
      @pending_kanji = JSON.parse(resp_pending.body)

      # 2. SỬA TẠI ĐÂY: Dùng tham số query để HTTParty tự encode chữ Kanji (日 -> %E6%97%A5)
      resp_master = HTTParty.get(BASE_URL,
                                 query: { keyword: @pending_kanji['kanji'], status: 'ACTIVE' },
                                 headers: API_HEADERS,
                                 verify: false)

      @master_kanji = JSON.parse(resp_master.body).first if resp_master.success?
    end

    # --- Phần logic PUT gửi dữ liệu duyệt ---
    payload = map_to_java_dto(get_safe_params)
    payload["status"] = "ACTIVE"
    payload["is_active"] = true

    response = HTTParty.put("#{BASE_URL}/#{kanji_id}/approve",
                            body: payload.to_json,
                            headers: API_HEADERS,
                            verify: false)

    if response.success?
      redirect_to admin_kanjis_path(status: 'PENDING'), notice: "Đã duyệt Kanji thành công!"
    else
      # Khi Java trả về lỗi (ví dụ: sai format On/Kun), ta render lại trang duyệt
      parsed = JSON.parse(response.body) rescue {}
      flash.now[:alert] = "Lỗi khi duyệt: #{parsed['message'] || 'Dữ liệu không hợp lệ'}"
      @errors = parsed['errors'] || {}

      # Đảm bảo @pending_kanji có ID để tránh lỗi UrlGenerationError ở dòng #76
      @form_data = payload.transform_keys(&:to_s)
      @form_data['id'] = kanji_id
      @pending_kanji['id'] = kanji_id if @pending_kanji

      render :review
    end
  end

  # ================= REJECT (TỪ CHỐI BÀI) =================
  # [QUAN TRỌNG] Hàm này phải là PUBLIC (nằm trên từ khóa private)
  def reject
    reason = params[:reason].to_s.strip

    response = HTTParty.put("#{BASE_URL}/#{params[:id]}/reject",
                            query: { reason: reason },
                            headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path(status: 'PENDING'), notice: "Đã từ chối bài đóng góp."
    else
      redirect_to admin_kanji_path(params[:id]), alert: "Lỗi Server: #{response.code}"
    end
  end

  # ================= PRIVATE METHODS =================
  private

  def get_safe_params
    params.require(:kanji).permit!
  rescue
    params.permit!
  end

  def map_to_java_dto(p)
    p = p.to_h.with_indifferent_access
    current_status = p[:status].presence || "ACTIVE"
    is_active_bool = (current_status == "ACTIVE")

    {
      "kanji"              => p[:kanji],
      "translation"        => p[:translation]&.upcase,
      "meaning"            => p[:meaning],
      "jlpt"               => safe_integer(p[:jlpt] || p[:jlpt_level]),
      "num_strokes"        => safe_integer(p[:num_strokes] || p[:stroke_count]),
      "on_pronunciation"   => p[:on_pronunciation] || p[:onyomi],
      "kun_pronunciation"  => p[:kun_pronunciation] || p[:kunyomi],
      "writing_image_url"  => p[:writing_image_url],
      "radical"            => p[:radical],
      "components"         => p[:components],
      "kanji_description"  => p[:kanji_description] || p[:kanji_story],
      "vocabulary"         => p[:vocabulary],
      "examples"           => p[:examples],
      "status"             => current_status,
      "is_active"          => is_active_bool
    }
  end

  def safe_integer(val); val.present? ? val.to_i : nil; end

  # Đưa hàm này xuống dưới private
  def load_comparison_data(kanji_data)
    return unless kanji_data['kanji'].present?
    check_res = HTTParty.get(BASE_URL, query: { kanji: kanji_data['kanji'], status: 'ACTIVE' }, headers: API_HEADERS, verify: false)
    existing_list = check_res.success? ? (JSON.parse(check_res.body)["data"] || []) : []
    @active_conflict = existing_list.find { |k| k["id"].to_s != kanji_data["id"].to_s && k["is_active"] == true }
    @lock_core_fields = @active_conflict.present?
  end
end
