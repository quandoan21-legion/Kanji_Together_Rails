class Admin::KanjisController < ApplicationController

  # 1. Cấu hình Link Server Ngrok (Lấy từ ảnh bạn gửi)
  BASE_URL = "https://454fbe6db3b4.ngrok-free.app/api/v1/kanjis"

  # 2. Header bắt buộc để vượt qua màn hình cảnh báo của Ngrok
  NGROK_HEADERS = {
    'ngrok-skip-browser-warning' => 'true',
    'Content-Type' => 'application/json'
  }

  def index
    begin
      # Thêm headers: NGROK_HEADERS vào request
      response = HTTParty.get(BASE_URL,
                              query: { page: params[:page] || 0 },
                              headers: NGROK_HEADERS)

      if response.success?
        @kanjis = JSON.parse(response.body)["data"] || []
      else
        @kanjis = []
        flash.now[:alert] = "Lỗi từ Server Ngrok: #{response.code}"
      end
    rescue JSON::ParserError
      @kanjis = []
      flash.now[:alert] = "Lỗi dữ liệu: Ngrok trả về HTML thay vì JSON (Kiểm tra lại Header)."
    rescue Errno::ECONNREFUSED, SocketError
      @kanjis = []
      flash.now[:alert] = "Không thể kết nối đến Server Ngrok. Kiểm tra lại link!"
    end
  end

  def new
    @kanji = {}
    @errors = {}
  end

  def edit
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: NGROK_HEADERS)

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
    # Dùng NGROK_HEADERS để có cả Content-Type lẫn quyền truy cập
    response = HTTParty.post(BASE_URL,
                             body: payload.to_json,
                             headers: NGROK_HEADERS)

    handle_response(response, payload, :new, "Tạo thành công!")
  end

  def update
    payload = kanji_params.to_h
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}",
                            body: payload.to_json,
                            headers: NGROK_HEADERS)

    handle_response(response, payload, :edit, "Cập nhật thành công !")
  end

  def destroy
    # Delete cũng cần header để Ngrok cho phép đi qua
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: NGROK_HEADERS)

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

  def handle_response(response, payload, render_view, success_message)
    if response.success?
      redirect_to admin_kanjis_path, notice: success_message
    else
      # Nếu Ngrok trả về HTML (Lỗi 502/404 hoặc trang Warning chưa bypass được)
      if response.parsed_response.is_a?(String)
        flash.now[:alert] = "Lỗi Server Ngrok (HTML Response). Có thể Server Java đang tắt hoặc Link sai."
        @errors = {}
      else
        # Java trả về JSON lỗi Validate (400)
        @errors = response.parsed_response['errors'] || {}
        flash.now[:alert] = response.parsed_response['message'] || "Dữ liệu không hợp lệ!"
      end

      @kanji = payload
      @kanji["id"] = params[:id] if params[:id]

      render render_view, status: :unprocessable_entity
    end
  rescue JSON::ParserError, SocketError
    flash.now[:alert] = "Lỗi kết nối Ngrok. Vui lòng kiểm tra lại Link Server!"
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
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: NGROK_HEADERS)
      @kanji = response.success? ? JSON.parse(response.body)["data"] : nil
      redirect_to admin_kanjis_path, alert: "Không tìm thấy Kanji" unless @kanji
    rescue
      redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server"
    end
  end
end