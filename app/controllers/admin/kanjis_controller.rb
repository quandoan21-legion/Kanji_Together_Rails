class Admin::KanjisController < ApplicationController

  # Đã đổi về Localhost
  BASE_URL = "http://localhost:8080/api/v1/kanjis"

  API_HEADERS = {
    'Content-Type' => 'application/json',
    'ngrok-skip-browser-warning' => 'true'
  }

  # ================= INDEX =================
  def index
    @kanjis = []
    @page_title = "Quản lý Kanji Hệ Thống"

    url =
      if params[:status].to_s == 'pending'
        @page_title = "Duyệt Kanji Người Dùng Gửi"
        "#{BASE_URL}/pending"
      else
        BASE_URL
      end

    response = HTTParty.get(url, headers: API_HEADERS, verify: false)

    if response.success?
      data = JSON.parse(response.body)
      @kanjis = data["data"] || []
    else
      flash.now[:alert] = "Lỗi lấy dữ liệu: #{response.code}"
    end
  rescue => e
    flash.now[:alert] = "Lỗi kết nối Server: #{e.message}"
  end

  # ================= NEW =================
  def new
    @kanji = {}
    @errors = {}
    @form_mode = :new
  end

  # ================= EDIT =================
  def edit
    response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      @kanji = JSON.parse(response.body)["data"]
      @errors = {}
      @form_mode = :edit
    else
      redirect_to admin_kanjis_path, alert: "Không tìm thấy Kanji ID: #{params[:id]}"
    end
  rescue
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server."
  end

  # ================= CREATE =================
  def create
    payload = map_to_java_dto(get_safe_params)

    response = HTTParty.post(
      BASE_URL,
      body: payload.to_json,
      headers: API_HEADERS,
      verify: false
    )

    handle_response(response, payload, :new, "Tạo thành công!")
  end

  # ================= UPDATE =================
  def update
    payload = map_to_java_dto(get_safe_params)

    response = HTTParty.put(
      "#{BASE_URL}/#{params[:id]}",
      body: payload.to_json,
      headers: API_HEADERS,
      verify: false
    )

    handle_response(response, payload, :edit, "Cập nhật thành công!")
  end

  # ================= DESTROY =================
  # Đảm bảo bạn đã khai báo đúng URL ở đầu Class
  # KANJI_API_URL = "http://localhost:8080/api/v1/kanjis"

  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: API_HEADERS, verify: false)

    if response.success?
      # status: :see_other là bắt buộc với Rails 7 (Turbo)
      redirect_to admin_kanjis_path, notice: "Đã xóa Kanji thành công!", status: :see_other
    else
      # Lấy lý do lỗi từ Java (nếu có)
      error_msg = JSON.parse(response.body)["message"] rescue response.code
      redirect_to admin_kanjis_path, alert: "Không thể xóa: #{error_msg}"
    end
  rescue => e
    redirect_to admin_kanjis_path, alert: "Lỗi kết nối Server: #{e.message}"
  end

  # ================= PARAMS =================
  def get_safe_params
    params[:kanji].present? ? params.require(:kanji).permit! : params.permit!
  end

  # ================= MAP DTO =================
  def map_to_java_dto(p)
    p = p.to_h.with_indifferent_access

    {
      "kanji"              => p[:kanji].presence,
      "translation"        => p[:translation].presence,
      "meaning"            => p[:meaning].presence,
      "jlpt"               => safe_integer(p[:jlpt] || p[:jlpt_level]),
      "num_strokes"        => safe_integer(p[:num_strokes] || p[:stroke_count]),
      "on_pronunciation"  => p[:on_pronunciation] || p[:onyomi],
      "kun_pronunciation" => p[:kun_pronunciation] || p[:kunyomi],
      "writing_image_url" => p[:writing_image_url],
      "radical"            => p[:radical],
      "components"         => p[:components],
      "kanji_description" => p[:kanji_description] || p[:kanji_story],
      "vocabulary"         => p[:vocabulary],
      "examples"           => p[:examples]
    }
  end

  # ================= HANDLE RESPONSE =================
  def handle_response(response, payload, render_view, success_msg)
    if response.success?
      redirect_to admin_kanjis_path, notice: success_msg
      return
    end

    parsed = response.parsed_response rescue {}

    @errors = parsed.is_a?(Hash) ? parsed['errors'] || {} : {}

    # 🔥 CHỈ SHOW ALERT KHI KHÔNG CÓ LỖI FIELD
    flash.now[:alert] = parsed['message'] if @errors.blank?

    @kanji = payload.transform_keys { |k| k.to_s.underscore }

    if render_view == :edit
      @kanji["id"] = params[:id]
      @form_mode = :edit
    else
      @form_mode = :new
    end

    render render_view, status: :unprocessable_entity
  rescue => e
    flash.now[:alert] = "Mất kết nối Java Server: #{e.message}"
    @kanji = payload.transform_keys { |k| k.to_s.underscore }
    @kanji["id"] = params[:id] if render_view == :edit
    @errors = {}
    @form_mode = render_view

    render render_view, status: :unprocessable_entity
  end


  # ================= UTILS =================
  def safe_integer(value)
    value.present? ? value.to_i : nil
  end
end