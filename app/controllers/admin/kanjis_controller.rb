class Admin::KanjisController < ApplicationController
  # ================= CẤU HÌNH LOCALHOST =================
  BASE_URL = "http://localhost:8080/api/v1/kanjis"

  API_HEADERS = {
    'Content-Type' => 'application/json'
  }

  skip_before_action :verify_authenticity_token, only: [:approve, :reject]

  # ================= INDEX =================
  def index
    @page_title = "Quản lý Kanji"
    java_params = { page: params[:page] || 0 }

    if params[:keyword].present?
      k = params[:keyword].strip
      java_params[:kanji] = k
      java_params[:search] = k
    end

    if params[:status].present?
      java_params[:status] = params[:status]
      case params[:status]
      when 'HIDDEN'
        java_params[:is_active] = false
      when 'ACTIVE'
        java_params[:is_active] = true
      end
    end

    begin
      response = HTTParty.get(BASE_URL, query: java_params, headers: API_HEADERS, verify: false)
      if response.success?
        data = JSON.parse(response.body)
        @kanjis = data["data"] || data || []
      else
        @kanjis = []
        flash.now[:alert] = "Lỗi tải dữ liệu: #{response.code}"
      end
    rescue => e
      @kanjis = []
      flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    end
  end

  # ================= SHOW =================
  def show
    # 1. GỌI API LẤY CHI TIẾT BẢN GHI HIỆN TẠI (Dựa vào ID trên URL)
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      @kanji = JSON.parse(response.body)["data"] || {}

      # =================================================================================
      # NHÓM 1: CHẾ ĐỘ DUYỆT BÀI (REVIEW) - Dành cho PENDING, REJECTED
      # =================================================================================
      if ['PENDING', 'REJECTED', 'APPROVED'].include?(@kanji['status']) && @kanji['is_active'] == false

        @pending_kanji = @kanji
        check_res = HTTParty.get(BASE_URL,
                                 query: { kanji: @pending_kanji['kanji'] },
                                 headers: API_HEADERS, verify: false)

        existing_list = check_res.success? ? (JSON.parse(check_res.body)["data"] || []) : []

        # Tìm bản ghi đang là Master (ACTIVE hoặc HIDDEN)
        @master_kanji = existing_list.find { |k| ['ACTIVE', 'HIDDEN'].include?(k['status']) }

        # --- [QUAN TRỌNG] LOGIC QUYẾT ĐỊNH DỮ LIỆU ĐỔ VÀO FORM ---
        if @master_kanji.present?
          # CASE A: Đã có bản gốc -> Form bên phải lấy dữ liệu GỐC
          @form_data = @master_kanji
          @lock_core_fields = true # Có thể dùng biến này để hiện cảnh báo
          flash.now[:warning] = "Chữ này đã tồn tại (#{@master_kanji['status']}). Form bên phải đang hiển thị dữ liệu GỐC để bạn chỉnh sửa."
        else
          # CASE B: Chưa có -> Form bên phải lấy dữ liệu USER GỬI
          @form_data = @pending_kanji
          @lock_core_fields = false
          flash.now[:info] = "Chữ này mới hoàn toàn. Form bên phải hiển thị dữ liệu ĐÓNG GÓP."
        end

        render :review

        # =================================================================================
        # NHÓM 2: CHẾ ĐỘ XEM CHI TIẾT (SHOW) - Dành cho bản Gốc (ACTIVE/HIDDEN)
        # =================================================================================
      else
        # Lấy lịch sử đóng góp của chữ này
        contrib_res = HTTParty.get("#{BASE_URL}/contributions",
                                   query: { kanji: @kanji['kanji'] },
                                   headers: API_HEADERS, verify: false)

        @contributions = contrib_res.success? ? (JSON.parse(contrib_res.body)["data"] || []) : []

        render :show
      end

    else
      redirect_to admin_kanjis_path, alert: "Không tìm thấy dữ liệu (API Error)."
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối: #{e.message}"
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

  def approve
    payload = map_to_java_dto(get_safe_params)

    # 2. Ép buộc trạng thái thành ACTIVE
    payload["status"] = "ACTIVE"
    payload["is_active"] = true

    # 3. Gửi Request kèm Body (payload)
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}/approve",
                            body: payload.to_json,
                            headers: API_HEADERS,
                            verify: false)

    if response.success?
      redirect_to admin_kanjis_path(status: 'PENDING'), notice: "Đã duyệt và xuất bản Kanji thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      flash.now[:alert] = "Lỗi khi duyệt: #{parsed['message'] || 'Dữ liệu không hợp lệ'}"
      @errors = parsed['errors'] || {}

      @kanji = payload.transform_keys(&:to_s)
      @kanji['id'] = params[:id]

      load_comparison_data(@kanji)
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