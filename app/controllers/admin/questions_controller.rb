require 'net/http'
require 'json'

class Admin::QuestionsController < ApplicationController
  # URL API của Java
  JAVA_API_URL = "http://localhost:8080/api/v1/questions"
  # MỚI: Thêm API lấy danh sách Kanji cho dropdown
  JAVA_KANJI_API_URL = "http://localhost:8080/api/v1/kanjis"

  layout 'application'

  # GET /admin/questions
  def index
    uri = URI(JAVA_API_URL)

    # MỚI: Chuẩn bị tham số lọc (Type) và tìm kiếm (Kanji)
    params_to_send = {}
    params_to_send[:type] = params[:type] if params[:type].present?
    params_to_send[:kanji] = params[:kanji] if params[:kanji].present? # <--- Tìm theo Kanji

    uri.query = URI.encode_www_form(params_to_send) if params_to_send.any?

    begin
      response = Net::HTTP.get(uri)
      @questions = JSON.parse(response)
    rescue StandardError => e
      @questions = []
      flash.now[:alert] = "Không thể kết nối đến Java API: #{e.message}"
    end
  end

  # GET /admin/questions/new
  def new
    # LOGIC TẠO MỚI:
    pre_selected_type = params[:type].present? ? params[:type] : ""

    # MỚI: Lấy danh sách Kanji để đổ vào dropdown
    @kanjis = fetch_kanjis

    # Khởi tạo object rỗng
    @question = {
      'question_type' => pre_selected_type,
      'question_text' => '',
      'correct_answer' => '',
      'wrong_answer_1' => '',
      'wrong_answer_2' => '',
      'wrong_answer_3' => '',
      'related_kanjis' => [] # Mảng rỗng cho Kanji liên quan
    }
  end

  # GET /admin/questions/:id/edit
  def edit
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")

    # MỚI: Lấy danh sách Kanji để đổ vào dropdown khi sửa
    @kanjis = fetch_kanjis

    response = Net::HTTP.get(uri)

    if response.empty? || response == "null"
      redirect_to admin_questions_path, alert: "Không tìm thấy câu hỏi!"
    else
      @question = JSON.parse(response)
    end
  rescue StandardError => e
    redirect_to admin_questions_path, alert: "Lỗi kết nối Java: #{e.message}"
  end

  # POST /admin/questions
  def create
    uri = URI(JAVA_API_URL)
    header = { 'Content-Type': 'application/json' }

    # MỚI: Sử dụng hàm build_payload để xử lý dữ liệu (đặc biệt là mảng Kanji)
    # Lưu ý: Form mới dùng scope :question nên phải lấy params[:question]
    question_params = params[:question] || params # Fallback nếu chưa sửa view
    payload = build_payload(question_params)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)

      if response.code.to_i == 200
        # Thành công
        redirect_to admin_questions_path(type: question_params[:question_type]), notice: "Tạo câu hỏi thành công!"
      else
        # Thất bại
        handle_error_response(response, payload)
        render :new
      end
    rescue StandardError => e
      handle_system_error(e, payload)
      render :new
    end
  end

  # PUT /admin/questions/:id
  def update
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")
    header = { 'Content-Type': 'application/json' }

    question_params = params[:question] || params
    payload = build_payload(question_params)
    # Đảm bảo có ID trong payload (dù Java lấy ID từ URL là chính)
    payload[:id] = id

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)

      if response.code.to_i == 200
        redirect_to admin_questions_path, notice: "Cập nhật thành công!"
      else
        handle_error_response(response, payload)
        render :edit
      end
    rescue StandardError => e
      handle_system_error(e, payload)
      render :edit
    end
  end

  # DELETE /admin/questions/:id
  def destroy
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)

    begin
      response = http.request(request)
      if response.code.to_i == 200
        redirect_to admin_questions_path, notice: "Đã xóa câu hỏi."
      else
        redirect_to admin_questions_path, alert: "Lỗi khi xóa: #{response.body.force_encoding('UTF-8')}"
      end
    rescue StandardError => e
      redirect_to admin_questions_path, alert: "Lỗi kết nối: #{e.message}"
    end
  end

  private

  # --- CÁC HÀM HỖ TRỢ (HELPER METHODS) ---

  # 1. Gọi API lấy danh sách Kanji
  def fetch_kanjis
    uri = URI(JAVA_KANJI_API_URL)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue
    [] # Trả về mảng rỗng nếu lỗi, để trang web không bị sập
  end

  # 2. Xây dựng dữ liệu gửi đi (Payload Builder)
  # Hàm này quan trọng: Nó chuyển đổi mảng ID ["1", "2"] thành mảng Object [{id:1}, {id:2}]
  def build_payload(p)
    data = {
      question_type: p[:question_type],
      question_text: p[:question_text],
      correct_answer: p[:correct_answer],
      wrong_answer_1: p[:wrong_answer_1],
      wrong_answer_2: p[:wrong_answer_2],
      wrong_answer_3: p[:wrong_answer_3],
      status: 1
    }

    # XỬ LÝ KANJI IDS (Mảng nhiều - nhiều)
    if p[:kanji_ids].present?
      # Loại bỏ giá trị rỗng và map sang object
      data[:related_kanjis] = p[:kanji_ids].reject(&:blank?).map { |id| { id: id.to_i } }
    end

    data
  end

  # 3. Xử lý lỗi trả về từ Java (để code gọn hơn)
  def handle_error_response(response, payload)
    @question = payload.stringify_keys
    @kanjis = fetch_kanjis

    error_body = JSON.parse(response.body.force_encoding('UTF-8')) rescue { 'message' => response.body }
    message = error_body['message'] || "Có lỗi xảy ra"
    details = error_body['errors']&.values&.join(', ')

    flash.now[:alert] = details ? "#{message}: #{details}" : message
  end

  # 4. Xử lý lỗi hệ thống/kết nối
  def handle_system_error(e, payload)
    @question = payload.stringify_keys
    @kanjis = fetch_kanjis # Load lại dropdown
    flash.now[:alert] = "Lỗi hệ thống: #{e.message}"
  end
end