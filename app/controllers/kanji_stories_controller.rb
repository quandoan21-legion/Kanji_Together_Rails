class KanjiStoriesController < ApplicationController
  BASE_URL = "http://109b-14-191-33-21.ngrok-free.app"
  HEADERS = { "ngrok-skip-browser-warning" => "true", "Content-Type" => "application/json" }

  def index
    @stories = []
  end

  def new
    @kanji_list = fetch_active_kanji
    @story = {}
  end

  def edit
    story_id = params[:id]
    response = HTTParty.get(
      "#{BASE_URL}/api/v1/kanji-stories/#{story_id}",
      headers: HEADERS,
      verify: false
    )

    if response.success?
      @story = response.parsed_response["data"] || {}
      @kanji_list = fetch_active_kanji
    else
      redirect_to kanji_stories_path, alert: "Story not found"
    end
  rescue => e
    redirect_to kanji_stories_path, alert: "Error: #{e.message}"
  end

  def create
    kanji_id = params[:kanji_id]
    kanji_text = params[:kanji_text]
    kanji_story = params[:kanji_story]

    if kanji_id.blank? || kanji_text.blank? || kanji_story.blank?
      flash.now[:alert] = "Please fill in all fields"
      @kanji_list = fetch_active_kanji
      @story = params.permit(:kanji_id, :kanji_text, :kanji_story)
      render :new
      return
    end

    payload = {
      kanji_id: kanji_id,
      kanji_text: kanji_text,
      kanji_story: kanji_story,
      approval_status: "approved"
    }

    response = HTTParty.post(
      "#{BASE_URL}/api/v1/kanji-stories",
      body: payload.to_json,
      headers: HEADERS,
      verify: false
    )

    if response.success?
      redirect_to kanji_stories_path, notice: "Kanji story created successfully!"
    else
      flash.now[:alert] = "Error creating story: #{response.parsed_response['message'] rescue 'Unknown error'}"
      @kanji_list = fetch_active_kanji
      @story = payload
      render :new
    end
  rescue => e
    flash.now[:alert] = "Error: #{e.message}"
    @kanji_list = fetch_active_kanji
    @story = params.permit(:kanji_id, :kanji_text, :kanji_story)
    render :new
  end

  def update
    story_id = params[:id]
    kanji_story = params[:kanji_story]

    if kanji_story.blank?
      flash.now[:alert] = "Story cannot be empty"
      @story = { id: story_id, kanji_story: kanji_story }
      @kanji_list = fetch_active_kanji
      render :edit
      return
    end

    # Fetch current story to get kanji_text and kanji_id
    current_story_response = HTTParty.get(
      "#{BASE_URL}/api/v1/kanji-stories/#{story_id}",
      headers: HEADERS,
      verify: false
    )

    if !current_story_response.success?
      flash.now[:alert] = "Error: Story not found"
      @story = { id: story_id, kanji_story: kanji_story }
      @kanji_list = fetch_active_kanji
      render :edit
      return
    end

    current_story = current_story_response.parsed_response["data"] || {}
    
    payload = {
      kanji_id: current_story["kanji_id"],
      kanji_text: current_story["kanji_text"],
      kanji_story: kanji_story,
      approval_status: "approved"
    }

    response = HTTParty.put(
      "#{BASE_URL}/api/v1/kanji-stories/#{story_id}",
      body: payload.to_json,
      headers: HEADERS,
      verify: false
    )

    if response.success?
      redirect_to kanji_stories_path, notice: "Kanji story updated successfully!"
    else
      error_message = response.parsed_response["message"] rescue response.body
      flash.now[:alert] = "Error updating story: #{error_message}"
      @story = current_story
      @kanji_list = fetch_active_kanji
      render :edit
    end
  rescue => e
    puts "Update Story Error: #{e.message}"
    puts e.backtrace.first(5)
    flash.now[:alert] = "Error: #{e.message}"
    @story = { id: story_id, kanji_story: kanji_story }
    @kanji_list = fetch_active_kanji
    render :edit
  end

  def generate_story
    kanji = params[:kanji]

    if kanji.blank?
      return render json: { success: false, error: "Kanji is required" }, status: :bad_request
    end

    payload = { kanji: kanji }

    response = HTTParty.post(
      "#{BASE_URL}/api/v1/ai-kanji/generate",
      body: payload.to_json,
      headers: HEADERS,
      verify: false
    )

    if response.success?
      # Extract story from the response data
      data = response.parsed_response["data"] || {}
      story_content = data["story"] || ""
      
      if story_content.blank?
        render json: { success: false, error: "No story generated" }, status: :bad_request
      else
        render json: { success: true, story: story_content }
      end
    else
      error_message = response.parsed_response["message"] rescue response.body
      render json: { 
        success: false, 
        error: error_message || "Failed to generate story" 
      }, status: :bad_request
    end
  rescue => e
    puts "Generate Story Error: #{e.message}"
    puts e.backtrace.first(5)
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  private

  def fetch_active_kanji
    response = HTTParty.get(
      "#{BASE_URL}/api/v1/kanjis",
      query: { status: "ACTIVE", is_active: true, size: 100 },
      headers: HEADERS,
      verify: false
    )

    if response.success?
      data = response.parsed_response["data"] || {}
      
      # Handle different response structures
      kanjis = []
      if data.is_a?(Array)
        kanjis = data
      elsif data["content"].is_a?(Array)
        kanjis = data["content"]
      elsif data["kanjis"].is_a?(Array)
        kanjis = data["kanjis"]
      end
      
      # Filter for ACTIVE status
      kanjis.select { |k| k["status"] == "ACTIVE" || k["is_active"] == true }
    else
      puts "API Error: #{response.code} - #{response.body}"
      []
    end
  rescue => e
    puts "Error fetching kanji: #{e.message}"
    puts e.backtrace.first(5)
    []
  end
end
