class Admin::CoursesController < ApplicationController
  API_URL = "#{Rails.configuration.x.api_base_url}/api/v1/courses"
  API_HEADERS = { "Content-Type" => "application/json" }

  def index
    response = HTTParty.get(API_URL, headers: API_HEADERS)
    if response.success?
      body = JSON.parse(response.body)
      @courses = body["data"] || []
    else
      @courses = []
      flash.now[:alert] = "Không thể lấy danh sách khóa học (#{response.code})."
    end
  rescue StandardError => e
    @courses = []
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
  end

  def show
    response = HTTParty.get("#{API_URL}/#{params[:id]}", headers: API_HEADERS)
    if response.success?
      @course = JSON.parse(response.body)["data"] || {}
    else
      redirect_to admin_courses_path, alert: "Không tìm thấy khóa học."
    end
  rescue StandardError => e
    redirect_to admin_courses_path, alert: "Lỗi kết nối: #{e.message}"
  end

  def new
    @course = {}
  end

  def edit
    response = HTTParty.get("#{API_URL}/#{params[:id]}", headers: API_HEADERS)
    if response.success?
      @course = JSON.parse(response.body)["data"] || {}
      load_selected_lessons(@course["lesson_ids"])
    else
      redirect_to admin_courses_path, alert: "Không tìm thấy khóa học."
    end
  rescue StandardError => e
    redirect_to admin_courses_path, alert: "Lỗi kết nối: #{e.message}"
  end

  def create
    payload = course_payload
    response = HTTParty.post(API_URL, headers: API_HEADERS, body: payload.to_json)
    if response.success?
      redirect_to admin_courses_path, notice: "Tạo khóa học thành công!"
    else
      error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ server"
      flash.now[:alert] = "Tạo thất bại: #{error_msg}"
      @course = payload
      load_selected_lessons(payload[:lesson_ids])
      render :new
    end
  rescue StandardError => e
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    @course = payload
    load_selected_lessons(payload[:lesson_ids])
    render :new
  end

  def update
    payload = course_payload
    response = HTTParty.put("#{API_URL}/#{params[:id]}", headers: API_HEADERS, body: payload.to_json)
    if response.success?
      redirect_to admin_courses_path, notice: "Cập nhật khóa học thành công!"
    else
      error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ server"
      flash.now[:alert] = "Cập nhật thất bại: #{error_msg}"
      @course = payload.merge("id" => params[:id])
      load_selected_lessons(payload[:lesson_ids])
      render :edit
    end
  rescue StandardError => e
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    @course = payload.merge("id" => params[:id])
    load_selected_lessons(payload[:lesson_ids])
    render :edit
  end

  def destroy
    response = HTTParty.delete("#{API_URL}/#{params[:id]}", headers: API_HEADERS)
    if response.success?
      redirect_to admin_courses_path, notice: "Đã xóa khóa học."
    else
      error_msg = JSON.parse(response.body)["message"] rescue response.code
      redirect_to admin_courses_path, alert: "Xóa thất bại: #{error_msg}"
    end
  rescue StandardError => e
    redirect_to admin_courses_path, alert: "Lỗi kết nối: #{e.message}"
  end

  private

  def load_selected_lessons(lesson_ids)
    @selected_lessons = []
    Array(lesson_ids).each do |lesson_id|
      response = HTTParty.get("#{Rails.configuration.x.api_base_url}/api/v1/lessons/#{lesson_id}",
                              headers: API_HEADERS)
      next unless response.success?

      lesson = JSON.parse(response.body)["data"] || {}
      @selected_lessons << {
        "id" => lesson_id,
        "kanji" => lesson["kanji"],
        "name" => lesson["name"],
        "jlpt" => lesson["jlpt"],
        "lessonDescription" => lesson["lessonDescription"]
      }
    rescue StandardError
      @selected_lessons << { "id" => lesson_id }
    end
  end

  def course_payload
    raw = params[:course] || {}
    lesson_ids = raw[:lesson_ids]
    lesson_ids = lesson_ids.split(",") if lesson_ids.is_a?(String)
    lesson_ids = Array(lesson_ids).reject(&:blank?).map(&:to_i)

    {
      name: raw[:name],
      description: raw[:description],
      category: raw[:category],
      thumbnail_url: raw[:thumbnail_url],
      cover_image_url: raw[:cover_image_url],
      time_to_finish: raw[:time_to_finish],
      lesson_ids: lesson_ids
    }
  end
end
