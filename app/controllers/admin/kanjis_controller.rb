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
    @kanji = {} # Khởi tạo hash rỗng để form không bị nil
  end

  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}")
    if response.success?
      @kanji = JSON.parse(response.body)["data"]
    else
      redirect_to admin_kanjis_path, alert: "Không tìm thấy dữ liệu Kanji"
    end
  end

  def create
    # CHÌA KHÓA: Phẳng hóa dữ liệu để Java nhận được 'meaning' và 'radical'
    payload = kanji_params.to_h

    response = HTTParty.post(BASE_URL,
                             body: payload.to_json,
                             headers: { 'Content-Type' => 'application/json' })
    if response.success?
      redirect_to admin_kanjis_path, notice: "Tạo thành công!"
    else
      @kanji = payload # Giữ lại dữ liệu đã nhập để hiện lại form
      flash.now[:alert] = "Lỗi : #{response.parsed_response['message']}"
      render :new, status: :unprocessable_entity
    end
  end

  def update
    payload = kanji_params.to_h
    response = HTTParty.put("#{BASE_URL}/#{params[:id]}",
                            body: payload.to_json,
                            headers: { 'Content-Type' => 'application/json' })
    if response.success?
      redirect_to admin_kanjis_path, notice: "Cập nhật thành công !"
    else
      @kanji = payload.merge("id" => params[:id])
      flash.now[:alert] = "Lỗi cập nhật: #{response.parsed_response['message']}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}")
    if response.success?
      redirect_to admin_kanjis_path, notice: "Đã xóa thành công!", status: :see_other
    else
      redirect_to admin_kanjis_path, alert: "Lỗi xóa: Chữ này đang có ràng buộc dữ liệu ", status: :see_other
    end
  end

  private

  def kanji_params
    # Đảm bảo permit đúng các trường để Java có thể map dữ liệu vào Entity
    params.require(:kanji).permit(
      :kanji, :translation, :meaning, :jlpt,
      :on_pronunciation, :kun_pronunciation, :num_strokes,
      :writing_image_url, :radical, :components, :kanji_description
    )
  end
end