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
    course_data = course_payload
    lesson_data = course_lesson_payload
    lesson_ids = lesson_data[:lesson_ids]
    
    puts "\n" + "="*80
    puts "🔵 [CREATE COURSE] STEP 1: CREATE COURSE"
    puts "="*80
    puts "Payload: #{course_data.to_json}"
    puts "URL: #{API_URL}"
    puts "="*80 + "\n"
    
    response = HTTParty.post(API_URL, headers: API_HEADERS, body: course_data.to_json)
    
    puts "\n" + "="*80
    puts "🔵 [CREATE COURSE] RESPONSE"
    puts "="*80
    puts "Status Code: #{response.code}"
    puts "Response Body: #{response.body}"
    puts "="*80 + "\n"
    
    if response.success?
      course_response = JSON.parse(response.body)["data"] || {}
      course_id = course_response["id"]
      
      # Step 2: Link lessons if any were selected
      if lesson_ids.any?
        puts "\n" + "="*80
        puts "🔵 [CREATE COURSE] STEP 2: LINK LESSONS"
        puts "="*80
        puts "Course ID: #{course_id}"
        puts "Lesson IDs: #{lesson_ids.inspect}"
        
        # Merge course data with lesson_ids for the PUT request
        update_payload = course_data.merge(lesson_ids: lesson_ids)
        puts "Payload: #{update_payload.to_json}"
        puts "URL: #{API_URL}/#{course_id}"
        puts "="*80 + "\n"
        
        lesson_response = HTTParty.put("#{API_URL}/#{course_id}", 
                                       headers: API_HEADERS, 
                                       body: update_payload.to_json)
        
        puts "\n" + "="*80
        puts "🔵 [CREATE COURSE] LESSON LINK RESPONSE"
        puts "="*80
        puts "Status Code: #{lesson_response.code}"
        puts "Response Body: #{lesson_response.body}"
        puts "="*80 + "\n"
        
        if lesson_response.success?
          redirect_to admin_courses_path, notice: "Tạo khóa học và liên kết bài học thành công!"
        else
          error_msg = JSON.parse(lesson_response.body)["message"] rescue "Có lỗi từ server"
          redirect_to admin_courses_path, alert: "Tạo khóa học thành công nhưng liên kết bài học thất bại: #{error_msg}"
        end
      else
        redirect_to admin_courses_path, notice: "Tạo khóa học thành công!"
      end
    else
      error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ server"
      flash.now[:alert] = "Tạo thất bại: #{error_msg}"
      @course = course_data
      load_selected_lessons(lesson_ids)
      render :new
    end
  rescue StandardError => e
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    @course = course_data
    load_selected_lessons(lesson_ids)
    render :new
  end

  def update
    course_data = course_payload
    lesson_data = course_lesson_payload
    lesson_ids = lesson_data[:lesson_ids]
    
    puts "\n" + "="*80
    puts "🔵 [UPDATE COURSE] STEP 1: UPDATE COURSE DATA"
    puts "="*80
    puts "Course ID: #{params[:id]}"
    puts "Payload: #{course_data.to_json}"
    puts "URL: #{API_URL}/#{params[:id]}"
    puts "="*80 + "\n"
    
    response = HTTParty.put("#{API_URL}/#{params[:id]}", headers: API_HEADERS, body: course_data.to_json)
    
    puts "\n" + "="*80
    puts "🔵 [UPDATE COURSE] RESPONSE"
    puts "="*80
    puts "Status Code: #{response.code}"
    puts "Response Body: #{response.body}"
    puts "="*80 + "\n"
    
    if response.success?
      # Step 2: Update lessons - send full course data + lesson_ids
      puts "\n" + "="*80
      puts "🔵 [UPDATE COURSE] STEP 2: LINK LESSONS"
      puts "="*80
      puts "Course ID: #{params[:id]}"
      puts "Lesson IDs: #{lesson_ids.inspect}"
      
      # Merge course data with lesson_ids for the PUT request
      update_payload = course_data.merge(lesson_ids: lesson_ids)
      puts "Payload: #{update_payload.to_json}"
      puts "URL: #{API_URL}/#{params[:id]}"
      puts "="*80 + "\n"
      
      lesson_response = HTTParty.put("#{API_URL}/#{params[:id]}", 
                                     headers: API_HEADERS, 
                                     body: update_payload.to_json)
      
      puts "\n" + "="*80
      puts "🔵 [UPDATE COURSE] LESSON LINK RESPONSE"
      puts "="*80
      puts "Status Code: #{lesson_response.code}"
      puts "Response Body: #{lesson_response.body}"
      puts "="*80 + "\n"
      
      redirect_to admin_courses_path, notice: "Cập nhật khóa học thành công!"
    else
      error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ server"
      flash.now[:alert] = "Cập nhật thất bại: #{error_msg}"
      @course = course_data.merge("id" => params[:id])
      load_selected_lessons(lesson_ids)
      render :edit
    end
  rescue StandardError => e
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    @course = course_data.merge("id" => params[:id])
    load_selected_lessons(lesson_ids)
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

    {
      name: raw[:name],
      description: raw[:description],
      category: raw[:category],
      thumbnail_url: raw[:thumbnail_url],
      cover_image_url: raw[:cover_image_url],
      time_to_finish: raw[:time_to_finish]
    }
  end

  def course_lesson_payload
    raw = params[:course] || {}
    lesson_ids = raw[:lesson_ids]
    lesson_ids = lesson_ids.split(",") if lesson_ids.is_a?(String)
    lesson_ids = Array(lesson_ids).reject(&:blank?).map(&:to_i)

    {
      lesson_ids: lesson_ids
    }
  end
end
