class Admin::KanjisController < ApplicationController

  # Cấu hình API Localhost
  BASE_URL = "http://localhost:8080/api/v1/kanjis"

  # Header
  API_HEADERS = {
    'Content-Type' => 'application/json'
  }

  def index
    begin
      response = HTTParty.get(BASE_URL, headers: API_HEADERS)
      if response.success?
        @kanjis = JSON.parse(response.body)["data"] || []
      else
        @kanjis = []
        flash.now[:alert] = "Lỗi từ Java Server: #{response.code}"
      end
    rescue Errno::ECONNREFUSED, SocketError
      @kanjis = []
      flash.now[:alert] = "Không kết nối được localhost:8080. Hãy chạy Java Spring Boot!"
    end
  end

  def new
    @kanji = {}
    @errors = {}
  end

  def edit
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS)
      if response.success?
        @kanji = JSON.parse(response.body)["data"]
        @errors = {}
      else
        redirect_to admin_kanjis_path, alert: "Không tìm thấy Kanji ID: #{params[:id]}"
      end
    rescue
      redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server."
    end
  end

  def create
    payload = kanji_params.to_h
    response = HTTParty.post(BASE_URL, body: payload.to_json, headers: API_HEADERS)
    handle_response(response, payload, :new, "Tạo thành công!")
  end

  def update
    payload = kanji_params.to_h
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}", body: payload.to_json, headers: API_HEADERS)
    handle_response(response, payload, :edit, "Cập nhật thành công!")
  end

  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS)
    if response.success?
      redirect_to admin_kanjis_path, notice: "Đã xóa thành công!", status: :see_other
    else
      redirect_to admin_kanjis_path, alert: "Lỗi xóa: #{response.code}"
    end
  rescue
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server."
  end

  private

  def handle_response(response, payload, render_view, success_msg)
    if response.success?
      redirect_to admin_kanjis_path, notice: success_msg
    else
      if response.parsed_response.is_a?(String)
        flash.now[:alert] = "Lỗi Server Java (HTML Response)."
        @errors = {}
      else
        @errors = response.parsed_response['errors'] || {}
        flash.now[:alert] = response.parsed_response['message'] || "Dữ liệu không hợp lệ."
      end
      @kanji = payload
      @kanji["id"] = params[:id] if params[:id]
      render render_view, status: :unprocessable_entity
    end
  rescue
    flash.now[:alert] = "Mất kết nối Java Server."
    @kanji = payload
    @errors = {}
    render render_view, status: :unprocessable_entity
  end

  def kanji_params
    params.require(:kanji).permit(
      :kanji, :translation, :meaning, :jlpt,
      :on_pronunciation, :kun_pronunciation, :num_strokes,
      :writing_image_url, :radical, :components, :kanji_description,
      :vocabulary, :examples
    )
  end
end