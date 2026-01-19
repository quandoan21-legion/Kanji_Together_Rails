require 'httparty'
class Admin::StoriesController < ApplicationController

  # CẤU HÌNH SERVER NGROK
  BASE_URL = "https://454fbe6db3b4.ngrok-free.app/api/v1/kanji-stories"

  API_HEADERS = {
    'Content-Type' => 'application/json',
    'ngrok-skip-browser-warning' => 'true'
  }

  def index
    # Thêm verify: false
    response = HTTParty.get(BASE_URL, query: {
      status: params[:status],
      kanji: params[:kanji],
      kanjiId: params[:kanji_id],
      page: params[:page] || 0
    }, headers: API_HEADERS, verify: false)

    @stories = response.success? ? JSON.parse(response.body)["data"] : []
  end

  def show
    puts "====> DANG TRUY CAP VAO DUYET ID: #{params[:id]}"

    # Thêm verify: false
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      @story = JSON.parse(response.body)["data"]
      @stories = []
      render :show
    else
      puts "====> LOI GOI API JAVA: #{response.code}"
      redirect_to admin_stories_path, alert: "Java Server không trả về dữ liệu"
    end
  end

  def approve
    url = "#{BASE_URL}/#{params[:id]}/approve"
    body_content = {
      "kanji" => params[:kanji],
      "translation" => params[:translation],
      "meaning" => params[:meaning],
      "jlpt" => params[:jlpt_level].to_i,
      "numStrokes" => params[:stroke_count].to_i,
      "onPronunciation" => params[:onyomi],
      "kunPronunciation" => params[:kunyomi],
      "writingImageUrl" => params[:writing_image_url],
      "radical" => params[:radical],
      "components" => params[:components],
      "kanjiDescription" => params[:kanji_description],
      "vocabulary" => params[:vocabulary],
      "examples" => params[:examples]
    }.to_json

    response = HTTParty.put(url, body: body_content, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_stories_path, notice: "Đã duyệt và cập nhật đầy đủ thông tin!"
    else
      # Nếu lỗi, quay lại form và giữ nguyên status pending để sửa tiếp
      error_msg = response.parsed_response['message'] rescue "Lỗi không xác định"
      redirect_to admin_stories_path(status: 'pending'), alert: "Lỗi Server Java: #{error_msg}"
    end
  end

  def reject
    url = "#{BASE_URL}/#{params[:id]}/reject"
    # Thêm verify: false
    response = HTTParty.put(url, query: { reason: params[:reason] }, headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_stories_path, notice: "Đã từ chối bài viết!"
    else
      redirect_to admin_stories_path, alert: "Lỗi khi từ chối bài viết"
    end
  end
end