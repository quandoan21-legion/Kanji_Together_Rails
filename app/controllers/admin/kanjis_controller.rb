class Admin::KanjisController < ApplicationController

  # CẤU HÌNH SERVER NGROK
  BASE_URL = "https://454fbe6db3b4.ngrok-free.app/api/v1/kanjis"

  API_HEADERS = {
    'Content-Type' => 'application/json',
    'ngrok-skip-browser-warning' => 'true'
  }

  def index
    @kanjis = []
    begin
      # 1. Logic chọn API: Pending (Chờ duyệt) hay Active (Đã duyệt)
      if params[:status].to_s == 'pending'
        url = "#{BASE_URL}"
        @page_title = "Duyệt Kanji Người Dùng Gửi"
      else
        url = BASE_URL
        @page_title = "Quản lý Kanji Hệ Thống"
      end

      # 2. GỌI API (Thêm verify: false để tránh lỗi SSL Ngrok)
      response = HTTParty.get(url, headers: API_HEADERS, verify: false)

      if response.success?
        data = JSON.parse(response.body)
        # Kiểm tra kỹ để tránh lỗi nil
        @kanjis = data["data"] if data && data["data"]
      else
        flash.now[:alert] = "Lỗi lấy dữ liệu: #{response.code}"
      end
    rescue => e
      flash.now[:alert] = "Lỗi kết nối Server: #{e.message}"
    end
  end

  def new
    @kanji = {}
    @errors = {}
  end

  def edit
    begin
      # Lấy chi tiết Kanji để hiện lên form sửa/duyệt
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
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
    # SỬA: Dùng map_to_java_dto để sửa định dạng dữ liệu trước khi gửi
    payload = map_to_java_dto(kanji_params)

    response = HTTParty.post(BASE_URL, body: payload.to_json, headers: API_HEADERS, verify: false)
    handle_response(response, payload, :new, "Tạo thành công!")
  end

  def update
    # SỬA: Dùng map_to_java_dto để sửa định dạng dữ liệu trước khi gửi (Fix lỗi 400)
    payload = map_to_java_dto(kanji_params)

    response = HTTParty.put("#{BASE_URL}/#{params[:id]}", body: payload.to_json, headers: API_HEADERS, verify: false)
    # Sau khi update thành công -> handle_response sẽ redirect về danh sách chính
    handle_response(response, payload, :edit, "Đã duyệt và cập nhật thành công!")
  end

  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)
    if response.success?
      redirect_to admin_kanjis_path, notice: "Đã xóa thành công!", status: :see_other
    else
      redirect_to admin_kanjis_path, alert: "Lỗi xóa: #{response.code}"
    end
  rescue
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server."
  end

  private

  # --- HÀM QUAN TRỌNG: CHUYỂN ĐỔI DỮ LIỆU ---
  # Java cần: numStrokes, jlpt (int)
  # Rails gửi: num_strokes, jlpt (string)
  # -> Hàm này giúp 2 bên hiểu nhau
  def map_to_java_dto(params)
    {
      "kanji" => params[:kanji],
      "translation" => params[:translation],
      "meaning" => params[:meaning],
      "jlpt" => params[:jlpt].to_i,               # Ép kiểu số
      "numStrokes" => params[:num_strokes].to_i,  # Đổi tên + ép kiểu
      "onPronunciation" => params[:on_pronunciation], # Đổi tên
      "kunPronunciation" => params[:kun_pronunciation], # Đổi tên
      "writingImageUrl" => params[:writing_image_url], # Đổi tên
      "radical" => params[:radical],
      "components" => params[:components],
      "kanjiDescription" => params[:kanji_description], # Đổi tên
      "vocabulary" => params[:vocabulary],
      "examples" => params[:examples]
      # isActive do Java tự xử lý
    }
  end

  def handle_response(response, payload, render_view, success_msg)
    if response.success?
      # Thành công -> Quay về trang danh sách chính (Active)
      redirect_to admin_kanjis_path, notice: success_msg
    else
      # Thất bại -> Báo lỗi
      if response.parsed_response.is_a?(String)
        flash.now[:alert] = "Lỗi Server Java (HTML Response/Ngrok Error)."
        @errors = {}
      else
        @errors = response.parsed_response['errors'] || {}
        flash.now[:alert] = response.parsed_response['message'] || "Dữ liệu không hợp lệ."
      end

      # Map ngược lại key để form hiển thị lại dữ liệu cũ khi lỗi
      @kanji = payload.transform_keys { |k| k.to_s.underscore }
      @kanji["id"] = params[:id] if params[:id]
      render render_view, status: :unprocessable_entity
    end
  rescue => e
    flash.now[:alert] = "Mất kết nối Java Server: #{e.message}"
    @kanji = payload ? payload.transform_keys { |k| k.to_s.underscore } : {}
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