require 'net/http'
require 'json'

class Admin::QuestionsController < ApplicationController
  # URL API của Java
  BASE_URL = Rails.configuration.x.api_base_url
  JAVA_API_URL = "#{BASE_URL}/api/v1/questions"
  JAVA_KANJI_API_URL = "#{BASE_URL}/api/v1/kanjis"

  layout 'application'

  # GET /admin/questions
  def index
    # 1. Xác định trang hiện tại (Mặc định là 1 nếu không có)
    @current_page = (params[:page] || 1).to_i

    uri = URI(JAVA_API_URL)

    # 2. Xây dựng tham số gửi đi (Gộp cả Lọc, Tìm kiếm và Phân trang)
    params_to_send = {}
    params_to_send[:type] = params[:type] if params[:type].present?
    params_to_send[:keyword] = params[:kanji] if params[:kanji].present?

    # Spring Boot tính trang từ 0, Ruby tính từ 1 nên phải trừ 1
    params_to_send[:page] = @current_page - 1
    params_to_send[:size] = 10

    uri.query = URI.encode_www_form(params_to_send)

    begin
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      # 3. Bóc tách dữ liệu từ đối tượng Page của Spring Boot
      if data.is_a?(Hash) && (data['content'] || data['content'].is_a?(Array))
        # Lấy danh sách câu hỏi để hiển thị ra bảng
        @questions = data['content']

        # Lấy thông tin meta để hiển thị thanh phân trang
        @total_pages = (data['totalPages'] || data['total_pages'] || 0).to_i
        @total_elements = (data['totalElements'] || data['total_elements'] || 0).to_i
      else
        # Trường hợp API trả về mảng cũ hoặc lỗi cấu trúc
        @questions = data.is_a?(Array) ? data : []
        @total_pages = 0
      end

    rescue StandardError => e
      @questions = []
      @total_pages = 0
      flash.now[:alert] = "Không thể kết nối đến Java API: #{e.message}"
    end
  end

  # GET /admin/questions/new
  def new
    pre_selected_type = params[:type].present? ? params[:type] : ""
    @kanjis = fetch_kanjis
    @question = {
      'question_type' => pre_selected_type,
      'kanji_ids' => []
    }
  end
  # app/controllers/admin/questions_controller.rb

  def show
    # Gọi API Java lấy chi tiết câu hỏi theo ID
    response = HTTParty.get("#{JAVA_API_URL}/#{params[:id]}")

    if response.success?
      @question = JSON.parse(response.body)
    else
      flash[:alert] = "Không tìm thấy câu hỏi!"
      redirect_to admin_questions_path
    end
  rescue StandardError => e
    flash[:alert] = "Lỗi kết nối Java API: #{e.message}"
    redirect_to admin_questions_path
  end
  # GET /admin/questions/:id/edit
  def edit
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")
    @kanjis = fetch_kanjis

    begin
      response = Net::HTTP.get(uri)
      if response.empty? || response == "null"
        redirect_to admin_questions_path, alert: "Không tìm thấy câu hỏi!"
      else
        raw_data = JSON.parse(response)

        # [DEBUG]: In dữ liệu Java trả về ra Terminal để kiểm tra nếu cần
        puts ">> JAVA RESPONSE RAW: #{raw_data}"

        # [FIX]: Dùng hàm chuẩn hóa dữ liệu thủ công
        @question = normalize_question_data(raw_data)
      end
    rescue StandardError => e
      redirect_to admin_questions_path, alert: "Lỗi kết nối Java: #{e.message}"
    end
  end

  # POST /admin/questions
  def create
    uri = URI(JAVA_API_URL)
    header = { 'Content-Type': 'application/json' }

    question_params = params[:question] || params
    payload = build_payload(question_params)

    http = http_client_for(uri)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)
      if response.code.to_i == 200
        redirect_to admin_questions_path(type: question_params[:question_type]), notice: "Tạo câu hỏi thành công!"
      else
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
    payload[:id] = id.to_i

    http = http_client_for(uri)
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
    http = http_client_for(uri)
    request = Net::HTTP::Delete.new(uri.request_uri)

    begin
      response = http.request(request)
      if response.code.to_i == 200
        redirect_to admin_questions_path, notice: "Đã xóa câu hỏi."
      else
        redirect_to admin_questions_path, alert: "Lỗi khi xóa: #{response.body}"
      end
    rescue StandardError => e
      redirect_to admin_questions_path, alert: "Lỗi kết nối: #{e.message}"
    end
  end

  private
  def http_client_for(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http
  end

  def fetch_kanjis
    # Gửi size lớn để lấy đủ danh sách chọn cho đề thi N1
    uri = URI("#{JAVA_KANJI_API_URL}?status=ACTIVE&is_active=true&size=1000")
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
    # [SỬA TẠI ĐÂY]: Log báo là 'data', bên trong là 'kanjis'
    if json.is_a?(Hash) && json['data'].is_a?(Hash)
      json['data']['kanjis'] || []
    else
      []
    end
  rescue StandardError => e
    puts "Lỗi fetch_kanjis trên Ubuntu: #{e.message}"
    []
  end

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

    if p[:kanji_ids].present?
      data[:kanji_ids] = p[:kanji_ids].reject(&:blank?).map(&:to_i)
    else
      data[:kanji_ids] = []
    end

    data
  end

  # [QUAN TRỌNG NHẤT]: Hàm này sửa lỗi mất dữ liệu khi Edit
  def normalize_question_data(data)
    # Khởi tạo hash mới
    q = {}

    # Copy ID
    q['id'] = data['id']

    # Map từng trường một cách thủ công để chắc chắn 100%
    # Bên trái là Key Form Ruby cần --- Bên phải là các trường hợp Java có thể trả về

    q['question_type']  = data['questionType']  || data['question_type']
    q['question_text']  = data['questionText']  || data['question_text']

    # Đáp án đúng
    q['correct_answer'] = data['correctAnswer'] || data['correct_answer']

    # Đáp án sai (Đây là chỗ bạn bị lỗi, map kỹ cả 3 trường hợp)
    q['wrong_answer_1'] = data['wrongAnswer1'] || data['wrong_answer1'] || data['wrong_answer_1']
    q['wrong_answer_2'] = data['wrongAnswer2'] || data['wrong_answer2'] || data['wrong_answer_2']
    q['wrong_answer_3'] = data['wrongAnswer3'] || data['wrong_answer3'] || data['wrong_answer_3']

    # Kanji IDs
    kanji_list = data['kanjiCharacters'] || data['kanji_characters'] || []
    q['kanji_ids'] = kanji_list.map { |k| k['id'] }
    q['kanjiCharacters'] = kanji_list # Giữ lại để debug view index nếu cần

    q
  end

  def handle_error_response(response, payload)
    @question = payload.stringify_keys
    @kanjis = fetch_kanjis
    error_body = JSON.parse(response.body) rescue { 'message' => response.body }
    message = error_body['message'] || "Có lỗi xảy ra"
    details = error_body['errors']&.values&.join(', ') || ""
    flash.now[:alert] = details.present? ? "#{message}: #{details}" : message
  end

  def handle_system_error(e, payload)
    @question = payload.stringify_keys
    @kanjis = fetch_kanjis
    flash.now[:alert] = "Lỗi hệ thống Ruby: #{e.message}"
  end
end
