class Admin::StoriesController < ApplicationController
  require 'uri'
  
  BASE_URL = "#{Rails.configuration.x.api_base_url}/api/v1/kanji-stories"

  API_HEADERS = {
    'Content-Type' => 'application/json'
  }

  skip_before_action :verify_authenticity_token, only: [:approve, :reject]


  def index
    @page_title = "Quản lý Câu chuyện Kanji"

    @current_page = (params[:page] || 1).to_i
    java_page = @current_page - 1
    java_page = 0 if java_page < 0

    java_params = { page: java_page }

    if params[:keyword].present?
      k = params[:keyword].strip
      java_params[:kanji] = k
    end

    if params[:status].present?
      java_params[:status] = params[:status]
    end

    begin
      response = HTTParty.get(BASE_URL, query: java_params, headers: API_HEADERS, verify: false)

      if response.success?
        body = JSON.parse(response.body)
        result_metadata = body["data"] || {}

        if result_metadata.is_a?(Hash)
          @stories = result_metadata["kanji_stories"] || result_metadata["stories"] || []
          @total_pages = result_metadata["totalPages"] || 1
          @total_elements = result_metadata["totalElements"] || 0
        elsif result_metadata.is_a?(Array)
          @stories = result_metadata
          @total_pages = 1
          @total_elements = result_metadata.length
        else
          @stories = []
          @total_pages = 1
          @total_elements = 0
        end
      else
        @stories = []
        @total_pages = 1
        @total_elements = 0
        flash.now[:alert] = "Backend trả về lỗi: #{response.code}"
      end
    rescue => e
      @stories = []
      @total_pages = 1
      @total_elements = 0
      flash.now[:alert] = "Lỗi kết nối Server: #{e.message}"
    end
  end

  # ================= SHOW =================
  def show
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      json_body = JSON.parse(response.body)
      @story = json_body["data"].is_a?(Array) ? json_body["data"].first : (json_body["data"] || {})

      if @story.blank?
        redirect_to admin_stories_path, alert: "Không tìm thấy câu chuyện."
      end
    else
      redirect_to admin_stories_path, alert: "Không tìm thấy dữ liệu (API Error: #{response.code})."
    end
  rescue => e
    puts ">>> LỖI TẠI SHOW: #{e.message}"
    redirect_to admin_stories_path, alert: "Lỗi kết nối hệ thống: #{e.message}"
  end

  # ================= DESTROY =================
  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      redirect_to admin_stories_path, notice: "Đã xóa câu chuyện thành công!", status: :see_other
    else
      error_msg = JSON.parse(response.body)["message"] rescue response.code
      redirect_to admin_stories_path, alert: "Không thể xóa: #{error_msg}"
    end
  rescue => e
    redirect_to admin_stories_path, alert: "Lỗi hệ thống: #{e.message}"
  end

  # ================= EDIT =================
  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      json_body = JSON.parse(response.body)
      @story = json_body["data"].is_a?(Array) ? json_body["data"].first : (json_body["data"] || {})

      if @story.blank?
        redirect_to admin_stories_path, alert: "Không tìm thấy câu chuyện."
      end
    else
      redirect_to admin_stories_path, alert: "Không tìm thấy dữ liệu (API Error: #{response.code})."
    end
  rescue => e
    puts ">>> LỖI TẠI EDIT: #{e.message}"
    redirect_to admin_stories_path, alert: "Lỗi kết nối hệ thống: #{e.message}"
  end

  # ================= UPDATE =================
  def update
    story_id = params[:id]
    kanji_story = params[:kanji_story]

    if kanji_story.blank?
      flash.now[:alert] = "Câu chuyện không được để trống"
      response = HTTParty.get("#{BASE_URL}/#{story_id}", headers: API_HEADERS, verify: false)
      @story = JSON.parse(response.body)["data"] rescue {}
      render :edit
      return
    end

    # Fetch current story to get kanji_text and kanji_id
    current_response = HTTParty.get("#{BASE_URL}/#{story_id}", headers: API_HEADERS, verify: false)
    
    if !current_response.success?
      flash.now[:alert] = "Lỗi: Không tìm thấy câu chuyện"
      render :edit
      return
    end

    current_story = JSON.parse(current_response.body)["data"] rescue {}
    
    payload = {
      kanji_id: current_story["kanji_id"],
      kanji_text: current_story["kanji_text"],
      kanji_story: kanji_story,
      approval_status: "approved"
    }

    response = HTTParty.put("#{BASE_URL}/#{story_id}",
                            body: payload.to_json,
                            headers: API_HEADERS,
                            verify: false)

    if response.success?
      redirect_to admin_stories_path, notice: "Đã cập nhật câu chuyện thành công!"
    else
      error_msg = JSON.parse(response.body)["message"] rescue "Có lỗi từ backend"
      flash.now[:alert] = "Cập nhật thất bại: #{error_msg}"
      @story = current_story
      render :edit
    end
  rescue => e
    puts ">>> LỖI TẠI UPDATE: #{e.message}"
    redirect_to admin_stories_path, alert: "Lỗi: #{e.message}"
  end

  # ================= APPROVE =================
  def approve
    story_id = params[:id]

    puts "\n" + "="*80
    puts "🔵 [APPROVE STORY] FETCHING STORY DATA"
    puts "="*80
    puts "Story ID: #{story_id}"
    puts "="*80 + "\n"

    # 1. FETCH the story data first
    fetch_response = HTTParty.get("#{BASE_URL}/#{story_id}", headers: API_HEADERS, verify: false)
    
    unless fetch_response.success?
      puts "❌ Failed to fetch story data!"
      redirect_to admin_stories_path, alert: "Không thể lấy dữ liệu câu chuyện."
      return
    end

    story_data = JSON.parse(fetch_response.body)["data"] || {}
    
    puts "📋 Story Data Retrieved:"
    puts story_data.to_json
    puts "="*80 + "\n"

    # 2. FETCH master kanji data to fill in missing fields
    kanji_id = story_data["kanji_id"]
    master_kanji = {}
    
    if kanji_id.present?
      puts "🔵 [APPROVE STORY] FETCHING MASTER KANJI DATA"
      puts "="*80
      puts "Kanji ID: #{kanji_id}"
      puts "="*80 + "\n"
      
      kanji_base_url = "#{Rails.configuration.x.api_base_url}/api/v1/kanjis"
      kanji_response = HTTParty.get("#{kanji_base_url}/#{kanji_id}", headers: API_HEADERS, verify: false)
      
      if kanji_response.success?
        kanji_data = JSON.parse(kanji_response.body)["data"]
        master_kanji = kanji_data.is_a?(Array) ? kanji_data.first : (kanji_data || {})
        puts "📋 Master Kanji Data Retrieved:"
        puts master_kanji.to_json
        puts "="*80 + "\n"
      else
        puts "⚠️  Could not fetch master kanji data, will use story data only"
      end
    end

    # 3. BUILD the payload with story data, filled with master kanji data where story data is null
    payload = {
      kanji_id: story_data["kanji_id"],
      kanji_text: story_data["kanji_text"] || master_kanji["kanji"],
      kanji_story: story_data["kanji_story"] || master_kanji["kanji_description"],
      user_translation: story_data["user_translation"] || master_kanji["translation"],
      user_meaning: story_data["user_meaning"] || master_kanji["meaning"],
      user_num_strokes: story_data["user_num_strokes"] || master_kanji["num_strokes"],
      user_radical: story_data["user_radical"] || master_kanji["radical"],
      user_components: story_data["user_components"] || master_kanji["components"],
      user_vocabulary: story_data["user_vocabulary"] || master_kanji["vocabulary"],
      user_examples: story_data["user_examples"] || master_kanji["examples"],
      user_onyomi: story_data["user_onyomi"] || master_kanji["on_pronunciation"],
      user_kunyomi: story_data["user_kunyomi"] || master_kanji["kun_pronunciation"],
      status: "APPROVED",
      is_active: true
    }

    puts "\n" + "="*80
    puts "🔵 [APPROVE STORY] FINAL REQUEST PAYLOAD"
    puts "="*80
    puts "Story ID: #{story_id}"
    puts "Payload: #{payload.to_json}"
    puts "URL: #{BASE_URL}/#{story_id}/approve"
    puts "="*80 + "\n"

    # 4. SEND the approval request with merged payload
    response = HTTParty.put("#{BASE_URL}/#{story_id}/approve",
                            body: payload.to_json,
                            headers: API_HEADERS,
                            verify: false)

    puts "\n" + "="*80
    puts "🔵 [APPROVE STORY] RESPONSE"
    puts "="*80
    puts "Status Code: #{response.code}"
    puts "Response Body: #{response.body}"
    puts "="*80 + "\n"

    if response.success?
      puts "✅ Approval successful!"
      redirect_to admin_stories_path(status: 'PENDING'), notice: "Đã duyệt câu chuyện thành công!"
    else
      puts "❌ Approval failed!"
      parsed = JSON.parse(response.body) rescue {}
      flash.now[:alert] = "Lỗi khi duyệt: #{parsed['message'] || 'Dữ liệu không hợp lệ'}"
      @errors = parsed['errors'] || {}
      @story = story_data

      render :show
    end
  rescue => e
    puts "⚠️  Exception: #{e.message}"
    puts e.backtrace.first(5)
    redirect_to admin_stories_path, alert: "Lỗi: #{e.message}"
  end

  # ================= REJECT =================
  def reject
    story_id = params[:id]
    reason = params[:reason].to_s.strip

    puts "\n" + "="*80
    puts "🔴 [REJECT STORY] REQUEST"
    puts "="*80
    puts "Story ID: #{story_id}"
    puts "Reason: #{reason}"
    puts "URL: #{BASE_URL}/#{story_id}/reject?reason=#{URI.encode_www_form_component(reason)}"
    puts "="*80 + "\n"

    response = HTTParty.put("#{BASE_URL}/#{story_id}/reject",
                            query: { reason: reason },
                            headers: API_HEADERS,
                            verify: false)

    puts "\n" + "="*80
    puts "🔴 [REJECT STORY] RESPONSE"
    puts "="*80
    puts "Status Code: #{response.code}"
    puts "Response Body: #{response.body}"
    puts "="*80 + "\n"

    if response.success?
      puts "✅ Rejection successful!"
      redirect_to admin_stories_path(status: 'PENDING'), notice: "Đã từ chối câu chuyện."
    else
      puts "❌ Rejection failed!"
      redirect_to admin_story_path(story_id), alert: "Lỗi Server: #{response.code}"
    end
  rescue => e
    puts "⚠️  Exception: #{e.message}"
    puts e.backtrace.first(5)
    redirect_to admin_stories_path, alert: "Lỗi: #{e.message}"
  end

  # ================= PRIVATE METHODS =================
  private

  def get_safe_params
    begin
      params.require(:kanji_story).permit!.to_h.with_indifferent_access
    rescue
      params.permit!.to_h.with_indifferent_access
    end
  end
end
