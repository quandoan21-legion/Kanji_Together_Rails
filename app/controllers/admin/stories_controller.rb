require 'httparty'
class Admin::StoriesController < ApplicationController
  # before_action :authenticate_admin!

  def index
    # THAY ĐỔI: Gửi tham số 'kanji' thay vì 'email' để khớp với Backend mới
    response = HTTParty.get("http://localhost:8080/api/v1/kanji-stories", query: {
      status: params[:status],
      kanji: params[:kanji],   # <-- Đã sửa dòng này
      kanjiId: params[:kanji_id],
      page: params[:page] || 0
    })
    @stories = response.success? ? JSON.parse(response.body)["data"] : []
  end

  # --- CÁC HÀM DƯỚI GIỮ NGUYÊN 100% ---
  def show
    puts "====> DANG TRUY CAP VAO DUYET ID: #{params[:id]}"

    response = HTTParty.get("http://localhost:8080/api/v1/kanji-stories/#{params[:id]}")

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
    url = "http://localhost:8080/api/v1/kanji-stories/#{params[:id]}/approve"

    body_content = {
      meaning: params[:meaning],
      translation: params[:translation],
      onyomi: params[:onyomi],
      kunyomi: params[:kunyomi],
      stroke_count: params[:stroke_count],
      jlpt_level: params[:jlpt_level]
    }.to_json

    response = HTTParty.put(url,
                            body: body_content,
                            headers: { 'Content-Type' => 'application/json' })

    if response.success?
      redirect_to admin_stories_path, notice: "Đã duyệt và đồng bộ dữ liệu sang Kanji hệ thống!"
    else
      redirect_to admin_stories_path, alert: "Lỗi đồng bộ Java: #{response.parsed_response['message']}"
    end
  end

  def reject
    url = "http://localhost:8080/api/v1/kanji-stories/#{params[:id]}/reject"
    response = HTTParty.put(url, query: { reason: params[:reason] })

    if response.success?
      redirect_to admin_stories_path, notice: "Đã từ chối bài viết thành công!"
    else
      redirect_to admin_stories_path, alert: "Lỗi khi từ chối bài viết"
    end
  end
end