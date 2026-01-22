require 'net/http'
require 'json'

class Admin::QuestionsController < ApplicationController
  # URL API của Java
  JAVA_API_URL = "http://localhost:8080/api/v1/questions"

  layout 'application'

  # GET /admin/questions
  def index
    uri = URI(JAVA_API_URL)
    # Truyền tham số lọc type sang Java nếu có
    uri.query = URI.encode_www_form(type: params[:type]) if params[:type].present?

    response = Net::HTTP.get(uri)
    @questions = JSON.parse(response) rescue []
  end

  # GET /admin/questions/new
  def new
    # LOGIC TẠO MỚI THÔNG MINH:
    # Lấy tham số type từ URL (nếu có) để điền sẵn vào form
    pre_selected_type = params[:type].present? ? params[:type] : ""

    # Khởi tạo object rỗng
    @question = {
      'question_type' => pre_selected_type,
      'question_text' => '',
      'correct_answer' => '',
      'wrong_answer_1' => '',
      'wrong_answer_2' => '',
      'wrong_answer_3' => ''
    }
  end

  # GET /admin/questions/:id/edit
  def edit
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")
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

    # Chuẩn bị dữ liệu từ Form
    payload = {
      question_type: params[:question_type],
      question_text: params[:question_text],
      correct_answer: params[:correct_answer],
      wrong_answer_1: params[:wrong_answer_1],
      wrong_answer_2: params[:wrong_answer_2],
      wrong_answer_3: params[:wrong_answer_3],
      status: 1
    }

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)

      if response.code.to_i == 200
        # Thành công -> Quay về danh sách (giữ nguyên bộ lọc hiện tại nếu muốn)
        redirect_to admin_questions_path(type: params[:question_type]), notice: "Tạo câu hỏi thành công!"
      else
        # Thất bại -> Giữ lại dữ liệu đã nhập để không phải gõ lại
        @question = payload.stringify_keys

        # Xử lý hiển thị lỗi tiếng Việt/Nhật không bị lỗi font
        error_body = JSON.parse(response.body.force_encoding('UTF-8')) rescue { 'message' => response.body }
        message = error_body['message'] || "Có lỗi xảy ra"
        details = error_body['errors']&.values&.join(', ')

        flash.now[:alert] = details ? "#{message}: #{details}" : message
        render :new
      end
    rescue StandardError => e
      @question = payload.stringify_keys
      flash.now[:alert] = "Lỗi hệ thống: #{e.message}"
      render :new
    end
  end

  # PUT /admin/questions/:id
  def update
    id = params[:id]
    uri = URI("#{JAVA_API_URL}/#{id}")
    header = { 'Content-Type': 'application/json' }

    payload = {
      id: id,
      question_type: params[:question_type],
      question_text: params[:question_text],
      correct_answer: params[:correct_answer],
      wrong_answer_1: params[:wrong_answer_1],
      wrong_answer_2: params[:wrong_answer_2],
      wrong_answer_3: params[:wrong_answer_3]
    }

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)

      if response.code.to_i == 200
        redirect_to admin_questions_path, notice: "Cập nhật thành công!"
      else
        @question = payload.stringify_keys

        error_body = JSON.parse(response.body.force_encoding('UTF-8')) rescue { 'message' => response.body }
        message = error_body['message'] || "Có lỗi xảy ra"
        details = error_body['errors']&.values&.join(', ')

        flash.now[:alert] = details ? "#{message}: #{details}" : message
        render :edit
      end
    rescue StandardError => e
      @question = payload.stringify_keys
      flash.now[:alert] = "Lỗi hệ thống: #{e.message}"
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
end