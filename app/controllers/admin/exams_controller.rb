class Admin::ExamsController < ApplicationController
  # Định nghĩa URL của API Java
  API_URL = "#{Rails.configuration.x.api_base_url}/api/v1/exams"
  QUESTIONS_API_URL = "#{Rails.configuration.x.api_base_url}/api/v1/questions"

  # 1. DANH SÁCH EXAM
  def index
    # Lấy tham số từ URL để lọc
    page = params[:page] || 0
    keyword = params[:keyword]
    type = params[:type]

    # Gọi API Java (kèm tham số lọc)
    response = HTTParty.get(API_URL, query: { page: page, size: 10, keyword: keyword, type: type })

    if response.success?
      data = JSON.parse(response.body)
      @exams = data['content']
      @total_pages = data['totalPages']
      @current_page = data['number']
    else
      @exams = []
      flash[:alert] = "Không thể kết nối đến Server Java"
    end
  end

  # 2. TRANG TẠO MỚI
  def new
    @exam = {} # Khởi tạo rỗng
    fetch_questions_for_selection # Lấy list câu hỏi để hiện checkbox
  end

  # 3. XỬ LÝ TẠO MỚI (POST)
  def create
    payload = build_payload # Đóng gói dữ liệu

    response = HTTParty.post(API_URL,
                             body: payload.to_json,
                             headers: { 'Content-Type' => 'application/json' })

    if response.success?
      redirect_to admin_exams_path, notice: "Tạo đề thi thành công!"
    else
      flash[:alert] = "Lỗi khi tạo: #{response.body}"
      fetch_questions_for_selection
      render :new
    end
  end

  # 4. TRANG CHỈNH SỬA
  def edit
    # Gọi API lấy chi tiết Exam (để điền sẵn vào form)
    response = HTTParty.get("#{API_URL}/#{params[:id]}")

    if response.success?
      @exam = JSON.parse(response.body)
      fetch_questions_for_selection
    else
      redirect_to admin_exams_path, alert: "Không tìm thấy đề thi."
    end
  end

  # 5. XỬ LÝ CẬP NHẬT (POST/PUT)
  def update
    payload = build_payload
    payload[:id] = params[:id].to_i # Thêm ID để Java biết là Update

    response = HTTParty.post(API_URL,
                             body: payload.to_json,
                             headers: { 'Content-Type' => 'application/json' })

    if response.success?
      redirect_to admin_exams_path, notice: "Cập nhật thành công!"
    else
      flash[:alert] = "Lỗi cập nhật: #{response.body}"
      fetch_questions_for_selection
      # Giữ lại dữ liệu vừa nhập để không bị mất
      @exam = params[:exam].to_unsafe_h
      @exam['question_ids'] = params[:question_ids]&.map(&:to_i)
      render :edit
    end
  end

  # 6. XÓA
  def destroy
    response = HTTParty.delete("#{API_URL}/#{params[:id]}")
    if response.success?
      redirect_to admin_exams_path, notice: "Đã xóa đề thi."
    else
      redirect_to admin_exams_path, alert: "Lỗi khi xóa."
    end
  end

  private

  # Lấy danh sách câu hỏi để hiển thị checkbox (Lấy 1000 câu để chọn cho thoải mái)
  def fetch_questions_for_selection
    response = HTTParty.get(QUESTIONS_API_URL, query: { size: 1000 })
    @all_questions = response.success? ? JSON.parse(response.body)['content'] : []
  end

  # [QUAN TRỌNG] Hàm đóng gói JSON gửi sang Java
  def build_payload
    {
      name: params[:name],
      type: params[:type],
      duration: params[:duration].to_i,
      pass_score: params[:pass_score].to_i,
      status: params[:status].to_i,
      target_rank: params[:target_rank],

      # Lấy mảng ID câu hỏi từ checkbox, ép kiểu sang số nguyên
      question_ids: params[:question_ids]&.map(&:to_i) || []
    }
  end
end
