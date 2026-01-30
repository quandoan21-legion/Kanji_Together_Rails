class Admin::LessonsController < ApplicationController
  # Cấu hình đường dẫn API Java
  API_URL = "http://localhost:8080/api/v1/lessons"

  # Đường dẫn API lấy Kanji để đổ vào dropdown
  KANJI_API_URL = "http://localhost:8080/api/v1/kanjis"

  API_HEADERS = { 'Content-Type' => 'application/json' }

  # --- HÀM HỖ TRỢ: Lấy danh sách Kanji đang Active ---
  def load_active_kanjis
    begin
      # Gọi API lấy 1000 bản ghi, chỉ lấy trạng thái ACTIVE
      response = HTTParty.get(KANJI_API_URL, query: { size: 1000, status: 'ACTIVE' }, headers: API_HEADERS)
      if response.success?
        body = JSON.parse(response.body)
        @active_kanjis = body["data"]["kanjis"] || []
      else
        @active_kanjis = []
      end
    rescue => e
      Rails.logger.error "Lỗi load Kanji: #{e.message}"
      @active_kanjis = []
    end
  end
  # ---------------------------------------------------

  # GET /admin/lessons
  def index
    @page_title = "Quản lý Bài học"

    # 1. Xử lý phân trang
    @current_page = (params[:page] || 1).to_i
    java_page = @current_page - 1
    java_page = 0 if java_page < 0

    # 2. Tham số lọc
    java_params = {
      search: params[:keyword],
      jlpt: params[:jlpt],
      status: params[:status],
      created_at: params[:created_at],
      page: java_page,
      size: 10
    }

    # 3. Gọi API
    begin
      response = HTTParty.get(API_URL, query: java_params, headers: API_HEADERS)

      if response.success?
        body = JSON.parse(response.body)
        data = body["data"] || {}
        @lessons = data["lessons"] || []
        @total_pages = data["totalPages"] || 1
        @total_elements = data["totalElements"] || 0
      else
        @lessons = []
        flash.now[:alert] = "Lỗi Backend: #{response.code}"
      end
    rescue => e
      @lessons = []
      flash.now[:alert] = "Không kết nối được Java: #{e.message}"
    end
  end

  # GET /admin/lessons/:id
  # GET /admin/lessons/:id
  def show
    begin
      response = HTTParty.get("#{API_URL}/#{params[:id]}", headers: API_HEADERS)

      if response.success?
        parsed_body = JSON.parse(response.body)
        # Gán trực tiếp đối tượng bài học vào @lesson
        # Đảm bảo lấy đúng key "data" từ ApiResponse của Java
        @lesson = parsed_body["data"]

        # DEBUG: Bạn hãy nhìn vào terminal chạy Rails, nếu thấy dòng này hiện ra
        # thì dữ liệu đã về đến nơi.
        puts "======= DỮ LIỆU BÀI HỌC TẠI TRANG SHOW ======="
        puts @lesson.inspect
        puts "=============================================="
      else
        flash[:alert] = "Không tìm thấy bài học (ID: #{params[:id]})"
        redirect_to admin_lessons_path
      end
    rescue => e
      flash[:alert] = "Lỗi kết nối Server: #{e.message}"
      redirect_to admin_lessons_path
    end
  end
  # GET /admin/lessons/new
  def new
    @lesson = {}
    load_active_kanjis # Load dữ liệu cho dropdown
  end

  # POST /admin/lessons
  def create
    raw_kanji_ids = params[:kanji_ids] || (params[:lesson] && params[:lesson][:kanji_ids])
    payload = {
      kanji: params[:kanji] || params.dig(:lesson, :kanji),
      jlpt: params[:jlpt] || params.dig(:lesson, :jlpt),
      lesson_description: params[:lesson_description] || params.dig(:lesson, :lesson_description),
      status: params[:status] || params.dig(:lesson, :status) || "ACTIVE",
      # Ép kiểu chặt chẽ sang số nguyên
      kanji_ids: raw_kanji_ids.present? ? raw_kanji_ids.reject(&:blank?).map(&:to_i) : []
    }


    puts ">>>>>> DỮ LIỆU GỬI SANG JAVA: #{payload.to_json}"

    begin
      response = HTTParty.post(API_URL, body: payload.to_json, headers: API_HEADERS)

      if response.success?
        flash[:notice] = "Tạo bài học thành công!"
        redirect_to admin_lessons_path
      else
        error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ Java"
        flash.now[:alert] = "Tạo thất bại: #{error_msg}"
        @lesson = payload
        load_active_kanjis
        render :new
      end
    rescue => e
      flash.now[:alert] = "Lỗi kết nối: #{e.message}"
      @lesson = payload
      load_active_kanjis
      render :new
    end
  end
  def edit
    begin
      response = HTTParty.get("#{API_URL}/#{params[:id]}", headers: API_HEADERS)
      if response.success?
        @lesson = JSON.parse(response.body)["data"]
        load_active_kanjis # Load dữ liệu cho dropdown
      else
        flash[:alert] = "Không tìm thấy bài học!"
        redirect_to admin_lessons_path
      end
    rescue
      flash[:alert] = "Lỗi kết nối!"
      redirect_to admin_lessons_path
    end
  end

  # PATCH/PUT /admin/lessons/:id
  def update
    raw_kanji_ids = params[:kanji_ids] || (params[:lesson] && params[:lesson][:kanji_ids])

    payload = {
      kanji: params[:kanji] || params.dig(:lesson, :kanji),
      jlpt: params[:jlpt] || params.dig(:lesson, :jlpt),
      lesson_description: params[:lesson_description] || params.dig(:lesson, :lesson_description),
      status: params[:status] || params.dig(:lesson, :status),
      kanji_ids: raw_kanji_ids.present? ? raw_kanji_ids.reject(&:blank?).map(&:to_i) : []
    }

    begin
      response = HTTParty.put("#{API_URL}/#{params[:id]}", body: payload.to_json, headers: API_HEADERS)

      if response.success?
        flash[:notice] = "Cập nhật thành công!"
        redirect_to admin_lessons_path
      else
        flash.now[:alert] = "Lỗi cập nhật từ backend"
        @lesson = payload.merge("id" => params[:id])
        load_active_kanjis
        render :edit
      end
    rescue => e
      flash.now[:alert] = "Lỗi kết nối: #{e.message}"
      @lesson = payload.merge("id" => params[:id])
      load_active_kanjis
      render :edit
    end
  end

  # DELETE /admin/lessons/:id
  def destroy
    begin
      response = HTTParty.delete("#{API_URL}/#{params[:id]}", headers: API_HEADERS)
      if response.success?
        flash[:notice] = "Đã xóa bài học!"
      else
        flash[:alert] = "Xóa thất bại!"
      end
    rescue
      flash[:alert] = "Lỗi kết nối!"
    end
    redirect_to admin_lessons_path
  end
end