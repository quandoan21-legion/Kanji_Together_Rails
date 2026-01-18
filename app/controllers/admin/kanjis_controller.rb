class Admin::KanjisController < ApplicationController
  BASE_URL = "http://localhost:8080/api/v1/kanjis"

  def index
    response = HTTParty.get(BASE_URL, query: { page: params[:page] || 0 })
    if response.success?
      @kanjis = JSON.parse(response.body)["data"] || []
    else
      @kanjis = []
      flash.now[:alert] = "Không thể kết nối với Server"
    end
  end

  def new
    @kanji = {}
    @errors = {} # Khởi tạo lỗi trống
  end

  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}")
    if response.success?
      @kanji = JSON.parse(response.body)["data"]
      @errors = {} # Khởi tạo lỗi trống khi vào trang edit
    else
      redirect_to admin_kanjis_path, alert: "Không tìm thấy dữ liệu Kanji"
    end
  end

  def create
    payload = kanji_params.to_h
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
      redirect_to admin_kanjis_path, alert: "Lỗi: #{response.parsed_response['message']}"
    end
  end

  private

  # Hàm dùng chung để xử lý kết quả trả về từ Java
  def handle_response(response, payload, render_view, success_message)
    if response.success?
      redirect_to admin_kanjis_path, notice: success_message
    else
      # Java cần trả về lỗi theo định dạng {"message": "...", "errors": {"field": "lỗi"}}
      @errors = response.parsed_response['errors'] || {}
      @kanji = payload
      @kanji["id"] = params[:id] if params[:id] # Đảm bảo giữ ID khi update lỗi

      flash.now[:alert] = response.parsed_response['message'] || "Vui lòng kiểm tra lại dữ liệu"
      render render_view, status: :unprocessable_entity
    end
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
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}")
    @kanji = response.success? ? JSON.parse(response.body)["data"] : nil
    redirect_to admin_kanjis_path, alert: "Không tìm thấy Kanji" unless @kanji
  end
end