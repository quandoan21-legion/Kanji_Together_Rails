require 'httparty'

class Admin::StoriesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:approve, :reject]

  STORY_API_URL = "http://localhost:8080/api/v1/kanji-stories"
  KANJI_API_URL = "http://localhost:8080/api/v1/kanjis"

  API_HEADERS = {
    'Content-Type' => 'application/json',
    'ngrok-skip-browser-warning' => 'true'
  }

  def index
    @page_title = "Duyệt đóng góp người dùng"
    java_params = { page: params[:page] || 0 }
    if params[:kanji_id].present?
      java_params[:kanjiId] = params[:kanji_id]
      @is_filtered_by_kanji = true
    end
    java_params[:status] = params[:status] if params[:status].present?
    java_params[:kanji] = params[:kanji].strip if params[:kanji].present?

    begin
      response = HTTParty.get(STORY_API_URL, query: java_params, headers: API_HEADERS, verify: false)
      if response.success?
        data = JSON.parse(response.body)
        @stories = data["data"] || []
        if @is_filtered_by_kanji && @stories.any?
          @target_kanji_text = @stories.first["kanji_text"]
          @page_title = "Quản lý đóng góp cho chữ: #{@target_kanji_text}"
        end
      else
        @stories = []
        flash.now[:alert] = "Lỗi: #{response.code}"
      end
    rescue => e
      @stories = []
      flash.now[:alert] = "Lỗi hệ thống: #{e.message}"
    end
  end

  def show
    res = HTTParty.get("#{STORY_API_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
    if res.success?
      @user_raw_data = JSON.parse(res.body)["data"]
      load_story_data(@user_raw_data)
      render :show
    else
      redirect_to admin_stories_path, alert: "Không thể lấy dữ liệu bài viết."
    end
  end

  def approve
    story_id = params[:id]
    detail_res = HTTParty.get("#{STORY_API_URL}/#{story_id}", headers: API_HEADERS, verify: false)
    return redirect_to admin_stories_path, alert: "Lỗi kết nối Java." unless detail_res.success?
    original_data = JSON.parse(detail_res.body)["data"]
    load_story_data(original_data)
    payload = {
      "kanji"             => params[:kanji].presence || original_data["kanji_text"],
      "translation"       => params[:translation].presence || @story["translation"],
      "meaning"           => params[:meaning].presence || @story["meaning"],
      "onyomi"            => params[:onyomi].presence || @story["onyomi"],
      "kunyomi"           => params[:kunyomi].presence || @story["kunyomi"],
      "stroke_count"      => params[:stroke_count].presence || @story["stroke_count"],
      "jlpt_level"        => params[:jlpt_level].presence || @story["jlpt_level"] || 5,
      "radical"           => params[:radical].presence || @story["radical"],
      "components"        => params[:components].presence || @story["components"],
      "writing_image_url" => params[:writing_image_url].presence || @story["writing_image_url"] || "https://example.com/placeholder.gif",
      "kanji_description" => params[:kanji_description].presence || @story["kanji_description"],
      "vocabulary"        => params[:vocabulary].presence || @story["vocabulary"],
      "examples"          => params[:examples].presence || @story["examples"]
    }
    res = HTTParty.put("#{STORY_API_URL}/#{story_id}/approve",
                       body: payload.to_json,
                       headers: API_HEADERS,
                       verify: false)

    if res.code == 200
      flash[:notice] = "Đã phê duyệt thành công!"
      redirect_to admin_stories_path(status: 'pending')
    else
      error_data = JSON.parse(res.body) rescue {}
      flash.now[:alert] = "Lỗi: #{error_data['message'] || 'Dữ liệu không hợp lệ'}".html_safe
      @user_raw_data = original_data
      @story.merge!(payload)
      render :show
    end
  end
  def destroy
    res = HTTParty.delete("#{STORY_API_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
    if [200, 204].include?(res.code)
      flash[:notice] = "Đã xóa vĩnh viễn bản ghi đóng góp thành công."
    else
      flash[:alert] = "Lỗi Java: Không thể xóa bản ghi này."
    end
    redirect_to admin_stories_path(status: 'pending')
  end

  def reject
    story_id = params[:id]
    target_status = (params[:status] || 'rejected').downcase
    # Lấy lý do từ params gửi lên
    reject_reason = params[:reason].to_s.strip

    # 1. Kiểm tra nhanh tại Rails để tránh gửi request vô ích nếu trống
    if target_status == 'rejected' && reject_reason.blank?
      flash[:alert] = "Lỗi: Bạn bắt buộc phải nhập lý do từ chối để người đóng góp biết đường sửa bài!"
      return redirect_to admin_story_path(story_id)
    end

    url = "#{STORY_API_URL}/#{story_id}/reject"

    # 2. Gửi request sang Java (Java lúc này đã có logic story.setRejectReason(reason))
    res = HTTParty.put(
      url,
      query: { status: target_status, reason: reject_reason },
      headers: API_HEADERS,
      verify: false
    )

    if res.code == 200
      flash[:notice] = "Đã cập nhật trạng thái bài viết thành #{target_status.upcase}!"
      # Chuyển hướng về đúng tab trạng thái tương ứng
      redirect_to admin_stories_path(status: target_status)
    else
      # 3. Xử lý khi Java báo lỗi (Ví dụ: Java validate regex hoặc logic nội bộ thất bại)
      error_data = JSON.parse(res.body) rescue {}
      flash[:alert] = "Lỗi Java: #{error_data['message'] || 'Không thể cập nhật trạng thái'}"
      redirect_to admin_story_path(story_id)
    end
  end

  private

  def load_story_data(raw_data)
    @story = raw_data.dup
    kanji_text = raw_data["kanji_text"]
    original_kanji_id = raw_data["kanji_id"]
    system_kanji = nil

    # 1. Tìm kiếm Kanji trong hệ thống
    if original_kanji_id.present?
      res = HTTParty.get("#{KANJI_API_URL}/#{original_kanji_id}", headers: API_HEADERS, verify: false)
      system_kanji = JSON.parse(res.body)["data"] if res.success?
    end

    if system_kanji.nil? && kanji_text.present?
      search_res = HTTParty.get(KANJI_API_URL, query: { kanji: kanji_text }, headers: API_HEADERS, verify: false)
      if search_res.success?
        found_list = JSON.parse(search_res.body)["data"]
        system_kanji = found_list.find { |k| k["kanji"] == kanji_text } if found_list.is_a?(Array)
      end
    end

    # 2. Phân loại trạng thái
    if system_kanji.present?
      @story["kanji_id"] = system_kanji["id"]
      active_val = system_kanji["is_active"]

      # Kiểm tra nếu is_active là true
      if active_val == true || active_val == 1 || active_val.to_s == "1"
        @story["is_official"] = true
        @kanji_status = "official" # Đang hoạt động
      else
        @story["is_official"] = false
        @kanji_status = "hidden"   # Có tồn tại nhưng đang bị ẩn
      end

      # Đổ dữ liệu hệ thống vào để Admin sửa (hoặc xem)
      @story["translation"]       = system_kanji["translation"]
      @story["meaning"]           = system_kanji["meaning"]
      @story["onyomi"]            = system_kanji["on_pronunciation"] || system_kanji["onyomi"]
      @story["kunyomi"]           = system_kanji["kun_pronunciation"] || system_kanji["kunyomi"]
      @story["stroke_count"]      = system_kanji["num_strokes"] || system_kanji["stroke_count"]
      @story["jlpt_level"]        = system_kanji["jlpt"]
      @story["radical"]           = system_kanji["radical"]
      @story["components"]        = system_kanji["components"]
      @story["writing_image_url"] = system_kanji["writing_image_url"]
      @story["kanji_description"] = system_kanji["kanji_description"]
      @story["vocabulary"]        = system_kanji["vocabulary"]
      @story["examples"]          = system_kanji["examples"]
    else
      @story["kanji_id"]    = nil
      @story["is_official"] = false
      @kanji_status         = "new" # Chưa có trong DB

      # Gán dữ liệu từ User đóng góp
      @story["translation"]       = raw_data["user_translation"]
      @story["onyomi"]            = raw_data["user_onyomi"]
      @story["kunyomi"]           = raw_data["user_kunyomi"]
      @story["meaning"]           = raw_data["user_meaning"]
      @story["stroke_count"]      = raw_data["user_num_strokes"]
      @story["radical"]           = raw_data["user_radical"]
      @story["kanji_description"] = raw_data["kanji_story"]
      @story["vocabulary"]        = raw_data["user_vocabulary"]
      @story["examples"]          = raw_data["user_examples"]
    end
  end
end