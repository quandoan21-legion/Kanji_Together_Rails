class Admin::KanjisController < ApplicationController
  # 1. Cấu hình chạy Localhost
  BASE_URL = "http://localhost:8080/api/v1/kanjis"

  def index
    # Localhost thường không cần header 'ngrok-skip...' nhưng vẫn cần bắt lỗi kết nối
    begin
      response = HTTParty.get(BASE_URL, query: { page: params[:page] || 0 })

      if response.success?
        @kanjis = JSON.parse(response.body)["data"] || []
      else
        @kanjis = []
        flash.now[:alert] = "Lỗi từ Server: #{response.code}"
      end
    rescue Errno::ECONNREFUSED, JSON::ParserError
      @kanjis = []
      flash.now[:alert] = "Không thể kết nối đến Java Server (localhost:8080). Hãy chắc chắn bạn đã chạy Backend!"
    end
  end

  def new
    @kanji = {}
    @errors = {}
  end

  def edit
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}")
      if response.success?
        @kanji = JSON.parse(response.body)["data"]
        @errors = {}
      else
        redirect_to admin_kanjis_path, alert: "Không tìm thấy dữ liệu Kanji (ID: #{params[:id]})"
      end
    rescue
      redirect_to admin_kanjis_path, alert: "Mất kết nối với Server khi tải dữ liệu."
    end
  end

  def create
    payload = kanji_params.to_h
    # Localhost vẫn cần Content-Type json
    response = HTTParty.post(BASE_URL,
                             body: payload.to_json,
                             headers: { 'Content-Type' => 'application/json' })
    handle_response(response, payload, :new, "Tạo thành công!")
  end

  def update
    payload = kanji_params.to_h
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}",
                            body: payload.to_json,
                            headers: { 'Content-Type' => 'application/json' })
    handle_response(response, payload, :edit, "Cập nhật thành công !")
  end

  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}")
    if response.success?
      redirect_to admin_kanjis_path, notice: "Đã xóa thành công!", status: :see_other
    else
      message = response.parsed_response['message'] rescue "Lỗi không xác định"
      redirect_to admin_kanjis_path, alert: "Lỗi: #{message}"
    end
  rescue
    redirect_to admin_kanjis_path, alert: "Không thể kết nối đến Server để xóa."
  end

  private

  # Hàm xử lý phản hồi thông minh (Giúp bạn biết tại sao ấn lưu bị lỗi)
  def handle_response(response, payload, render_view, success_message)
    if response.success?
      redirect_to admin_kanjis_path, notice: success_message
    else
      # Kiểm tra nếu Java trả về HTML lỗi (Tomcat Error Page) thay vì JSON
      if response.parsed_response.is_a?(String)
        flash.now[:alert] = "Lỗi Server (500). Java đang trả về HTML thay vì JSON."
        @errors = {}
      else
        # Trường hợp Java trả về JSON lỗi Validate (400)
        @errors = response.parsed_response['errors'] || {}
        flash.now[:alert] = response.parsed_response['message'] || "Dữ liệu không hợp lệ, vui lòng kiểm tra lại!"
      end

      @kanji = payload
      @kanji["id"] = params[:id] if params[:id]

      render render_view, status: :unprocessable_entity
    end
  rescue JSON::ParserError, Errno::ECONNREFUSED
    # Bắt lỗi nếu Java chưa bật hoặc trả về dữ liệu rác
    flash.now[:alert] = "Không thể kết nối Server Java (Connection Refused). Hãy kiểm tra lại Backend!"
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

  def show
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}")
      @kanji = response.success? ? JSON.parse(response.body)["data"] : nil
      redirect_to admin_kanjis_path, alert: "Không tìm thấy Kanji" unless @kanji
    rescue
      redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server"
    end
  end
end