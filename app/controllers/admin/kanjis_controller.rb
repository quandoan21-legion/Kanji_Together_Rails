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
        # Hỗ trợ cả Pageable (content) và List (data)
        @kanjis = data["content"] || data["data"] || data || []
      else
        @kanjis = []
        flash.now[:alert] = "Lỗi tải dữ liệu: #{response.code}"
      end
    rescue => e
      @kanjis = []
      flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    end
  end

  # ================= SHOW (REVIEW & DETAIL) =================
  def show
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      @kanji = JSON.parse(response.body)["data"] || {}

      # -------------------------------------------------------------------------
      # CHẾ ĐỘ DUYỆT BÀI (REVIEW) - Dành cho các bài PENDING của User
      # -------------------------------------------------------------------------
      if ['PENDING', 'REJECTED', 'APPROVED'].include?(@kanji['status'])
        @pending_kanji = @kanji

        # Tìm bản Master trong DB (Không phân biệt Active/Hidden/Deleted)
        check_res = HTTParty.get(BASE_URL, query: { kanji: @pending_kanji['kanji'] }, headers: API_HEADERS, verify: false)
        res_body = JSON.parse(check_res.body)
        existing_list = res_body["content"] || res_body["data"] || []

        @master_kanji = existing_list.find { |k| ['ACTIVE', 'HIDDEN', 'DELETED'].include?(k['status']) }

        if @master_kanji.present?
          @form_data = @master_kanji
          # QUY TẮC: Chỉ khóa nếu Master đang ACTIVE. Nếu HIDDEN/DELETED thì MỞ (false)
          @lock_core_fields = (@master_kanji['status'] == 'ACTIVE')

          if @lock_core_fields
            flash.now[:warning] = "Chữ này đang HOẠT ĐỘNG. Bạn chỉ được phép sửa thông tin bổ sung."
          else
            flash.now[:info] = "Chữ này đã có trong DB nhưng đang ở trạng thái #{@master_kanji['status']}. Bạn được phép sửa toàn bộ."
          end
        else
          # Chữ mới hoàn toàn
          @form_data = @pending_kanji
          @lock_core_fields = false
          flash.now[:info] = "Chữ mới hoàn toàn. Bạn có quyền biên tập tất cả các trường."
        end

        render :review

        # -------------------------------------------------------------------------
        # CHẾ ĐỘ XEM CHI TIẾT (SHOW MASTER)
        # -------------------------------------------------------------------------
      else
        contrib_res = HTTParty.get("#{BASE_URL}/contributions", query: { kanji: @kanji['kanji'] }, headers: API_HEADERS, verify: false)
        @contributions = contrib_res.success? ? (JSON.parse(contrib_res.body)["data"] || []) : []
        render :show
      end
    else
      redirect_to admin_kanjis_path, alert: "API Error: Không tìm thấy ID #{params[:id]}"
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi hệ thống: #{e.message}"
  end

  # ================= NEW / CREATE =================
  def new
    @kanji = {}
    @errors = {}
    @form_mode = :new
  end

  def create
    payload = map_to_java_dto(get_safe_params)
    # Admin tạo luôn để status là ACTIVE
    payload["status"] = "ACTIVE"
    payload["is_active"] = true

    response = HTTParty.post(BASE_URL, body: payload.to_json, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path, notice: "Tạo mới Kanji thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      @errors = parsed['errors'] || {}
      flash.now[:alert] = parsed['message'] || "Tạo thất bại"
      @kanji = payload
      render :new
    end
  end

  # ================= EDIT / UPDATE =================
  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
    if response.success?
      @kanji = JSON.parse(response.body)["data"] || {}
      # Áp dụng quy tắc khóa tương tự như Show
      @lock_core_fields = (@kanji['status'] == 'ACTIVE')
      @form_mode = :edit
    else
      redirect_to admin_kanjis_path, alert: "Lỗi lấy dữ liệu Edit"
    end
  end

  def update
    payload = map_to_java_dto(get_safe_params)
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}", body: payload.to_json, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path, notice: "Cập nhật thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      @errors = parsed['errors'] || {}
      flash.now[:alert] = "Cập nhật thất bại!"
      @kanji = payload
      @kanji['id'] = params[:id]
      render :edit
    end
  end

  # ================= APPROVE / REJECT =================
  def approve
    payload = map_to_java_dto(get_safe_params)
    payload["status"] = "ACTIVE"
    payload["is_active"] = true

    response = HTTParty.put("#{BASE_URL}/#{params[:id]}/approve", body: payload.to_json, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path(status: 'PENDING'), notice: "Đã duyệt và cập nhật bản Master thành công!"
    else
      parsed = JSON.parse(response.body) rescue {}
      flash.now[:alert] = "Duyệt thất bại: #{parsed['message']}"
      @errors = parsed['errors'] || {}
      @kanji = payload.transform_keys(&:to_s)
      @kanji['id'] = params[:id]

      # Load lại dữ liệu so sánh để render lại trang review khi có lỗi validate
      load_comparison_data(@kanji)
      render :review
    end
  end

  def reject
    reason = params[:reason].to_s.strip
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}/reject", query: { reason: reason }, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_kanjis_path(status: 'PENDING'), notice: "Đã từ chối bài đóng góp."
    else
      redirect_to admin_kanji_path(params[:id]), alert: "Lỗi Server khi từ chối."
    end
  end

  # ================= DESTROY =================
  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
    if response.success?
      redirect_to admin_kanjis_path, notice: "Xóa thành công!", status: :see_other
    else
      redirect_to admin_kanjis_path, alert: "Không thể xóa."
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
    # Giữ nguyên cấu trúc key để khớp với KanjiCharacterDTO bên Java
    {
      "kanji"              => p[:kanji],
      "translation"        => p[:translation]&.upcase,
      "meaning"            => p[:meaning],
      "jlpt"               => safe_integer(p[:jlpt]),
      "num_strokes"        => safe_integer(p[:num_strokes] || p[:num_strokes]),
      "on_pronunciation"   => p[:on_pronunciation],
      "kun_pronunciation"  => p[:kun_pronunciation],
      "writing_image_url"  => p[:writing_image_url],
      "radical"            => p[:radical],
      "components"         => p[:components],
      "kanji_description"  => p[:kanji_description] || p[:kanji_description],
      "vocabulary"         => p[:vocabulary],
      "examples"           => p[:examples],
      "status"             => p[:status] || "ACTIVE",
      "is_active"          => p[:is_active].nil? ? true : p[:is_active]
    }
  end

  def safe_integer(val); val.present? ? val.to_i : nil; end

  def load_comparison_data(kanji_data)
    return unless kanji_data['kanji'].present?
    # Tìm kiếm Master bất kể trạng thái để quyết định lock trường khi render lại form lỗi
    check_res = HTTParty.get(BASE_URL, query: { kanji: kanji_data['kanji'] }, headers: API_HEADERS, verify: false)
    res_body = JSON.parse(check_res.body)
    existing_list = res_body["content"] || res_body["data"] || []
    @master_kanji = existing_list.find { |k| ['ACTIVE', 'HIDDEN', 'DELETED'].include?(k['status']) }
    @lock_core_fields = @master_kanji.present? && @master_kanji['status'] == 'ACTIVE'
  end
end