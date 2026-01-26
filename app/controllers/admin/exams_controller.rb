require 'net/http'
require 'json'

class Admin::ExamsController < ApplicationController
  JAVA_EXAMS_URL = "http://localhost:8080/api/v1/exams"
  JAVA_QUESTIONS_URL = "http://localhost:8080/api/v1/questions"

  layout 'application'

  def index
    uri = URI(JAVA_EXAMS_URL)
    response = Net::HTTP.get(uri)
    @exams = JSON.parse(response) rescue []
  end

  def new
    @exam = { 'duration' => 45, 'passScore' => 50, 'targetRank' => 'UNRANKED' }
    @questions = fetch_all_questions
  end

  def edit
    uri = URI("#{JAVA_EXAMS_URL}/#{params[:id]}")
    response = Net::HTTP.get(uri)
    @exam = JSON.parse(response)
    @questions = fetch_all_questions
  rescue
    redirect_to admin_exams_path, alert: "Không tìm thấy đề thi"
  end

  def create
    uri = URI(JAVA_EXAMS_URL)
    header = { 'Content-Type': 'application/json' }
    payload = build_payload(params[:exam])

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)
      if response.code.to_i == 200
        redirect_to admin_exams_path, notice: "Tạo đề thi thành công!"
      else
        handle_error_response(response, payload)
        @questions = fetch_all_questions
        render :new
      end
    rescue StandardError => e
      flash.now[:alert] = "Lỗi kết nối: #{e.message}"
      @questions = fetch_all_questions
      @exam = payload.stringify_keys
      render :new
    end
  end

  def update
    uri = URI("#{JAVA_EXAMS_URL}/#{params[:id]}")
    header = { 'Content-Type': 'application/json' }
    payload = build_payload(params[:exam])

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri, header)
    request.body = payload.to_json

    begin
      response = http.request(request)
      if response.code.to_i == 200
        redirect_to admin_exams_path, notice: "Cập nhật thành công!"
      else
        handle_error_response(response, payload)
        @questions = fetch_all_questions
        render :edit
      end
    rescue StandardError => e
      flash.now[:alert] = "Lỗi hệ thống: #{e.message}"
      @questions = fetch_all_questions
      @exam = payload.stringify_keys
      render :edit
    end
  end

  def destroy
    uri = URI("#{JAVA_EXAMS_URL}/#{params[:id]}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    http.request(request)
    redirect_to admin_exams_path, notice: "Đã xóa đề thi."
  end

  private

  def fetch_all_questions
    uri = URI(JAVA_QUESTIONS_URL)
    response = Net::HTTP.get(uri)
    JSON.parse(response) rescue []
  end

  def build_payload(p)
    data = {
      name: p[:name],
      examType: p[:exam_type],
      targetRank: p[:target_rank],
      duration: p[:duration].to_i,
      passScore: p[:pass_score].to_i,
      status: 1,
      totalQuestions: 0
    }

    if p[:question_ids].present?
      selected_ids = p[:question_ids].reject(&:blank?)
      # Java cần mảng object: [{id: 1}, {id: 2}]
      data[:questions] = selected_ids.map { |id| { id: id.to_i } }
      data[:totalQuestions] = selected_ids.size
    end

    data
  end

  # Hàm xử lý lỗi tập trung để tránh lỗi Incompatible Character Encodings
  def handle_error_response(response, payload)
    @exam = payload.stringify_keys

    # Ép kiểu dữ liệu trả về từ Java sang UTF-8
    raw_body = response.body.to_s.force_encoding("UTF-8")

    begin
      error_data = JSON.parse(raw_body)
      message = error_data['message'] || "Có lỗi xảy ra từ phía server"
      # Nếu Java trả về list lỗi chi tiết (Validation)
      details = error_data['errors']&.values&.join(', ')
      flash.now[:alert] = details ? "#{message}: #{details}" : message
    rescue
      flash.now[:alert] = "Lỗi hệ thống: #{raw_body}"
    end
  end
end