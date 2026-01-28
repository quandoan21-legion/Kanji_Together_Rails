# frozen_string_literal: true
require 'httparty'

class Admin::UsersController < ApplicationController
  # Cấu hình API
  BASE_URL = "http://localhost:8080/api/v1/users"
  HEADERS = { "Content-Type" => "application/json" }

  # --- 1. INDEX ---
  def index
    is_active = case params[:status]
                when 'ACTIVE' then true
                when 'BANNED' then false
                else nil
                end

    query_params = {
      name: params[:keyword],
      email: params[:keyword],
      active: is_active,
      page: (params[:page] || 1).to_i - 1,
      size: 10
    }
    begin
      response = HTTParty.get(BASE_URL, query: query_params, headers: HEADERS)
      if response.success?
        res = JSON.parse(response.body)['data']
        @users = res['content']
        @total_pages = res['total_pages'] || res['totalPages'] || 1
        @current_page = (res['number'] || res['page_number'] || 0) + 1
      else
        handle_api_error(response)
      end
    rescue StandardError => e
      handle_connection_error(e)
    end
  end

  # --- 2. NEW ---
  def new
    @user = User.new
  end

  # --- 3. SHOW (ĐÃ SỬA: Lấy data tươi từ API và map chuẩn xác) ---
  def show
    # Lấy khung user từ local DB (để tránh lỗi nil class trong view)
    @user = User.find_by(id: params[:id])

    unless @user
      redirect_to admin_users_path, alert: "Không tìm thấy người dùng trong DB Local"
      return
    end

    # Gọi API lấy dữ liệu mới nhất
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: HEADERS)

      if response.success?
        api_data = JSON.parse(response.body)['data']

        # --- QUAN TRỌNG: Map dữ liệu API vào object @user ---
        # Java trả về camelCase (isActive, isVerified), ta cần gán vào snake_case của Rails

        # 1. Trạng thái Active
        @user.is_active = api_data['isActive']
        @user.is_active = api_data['is_active'] if @user.is_active.nil? # Fallback

        # 2. Trạng thái Verified
        @user.is_verified = api_data['isVerified']
        @user.is_verified = api_data['is_verified'] if @user.is_verified.nil? # Fallback

        # 3. Các thông tin khác
        @user.rank = api_data['rank'] if api_data['rank'].present?
        @user.role = api_data['role'] if api_data['role'].present?
        @user.avatar_url = api_data['avatarUrl'] if api_data['avatarUrl'].present?
      end
    rescue StandardError => e
      Rails.logger.error "API Error: #{e.message}"
    end
  end

  # --- 4. EDIT ---
  def edit
    @user = User.find(params[:id])
    begin
      response = HTTParty.get("#{BASE_URL}/#{params[:id]}", headers: HEADERS)
      if response.success?
        api_data = JSON.parse(response.body)['data']

        # Map dữ liệu Active chuẩn
        real_status = api_data['isActive']
        real_status = api_data['is_active'] if real_status.nil?
        @user.is_active = real_status

        @user.rank = api_data['rank']
        @user.role = api_data['role']

        # Map verified để form hiển thị đúng nếu cần
        real_verified = api_data['isVerified']
        real_verified = api_data['is_verified'] if real_verified.nil?
        @user.is_verified = real_verified
      end
    rescue StandardError => e
      Rails.logger.error "Không lấy được data từ API: #{e.message}"
    end
  end

  # --- 5. CREATE ---
  def create
    payload = user_params.to_h.merge({
                                       password_hash: "Default@123",
                                       display_name: user_params[:name],
                                       avatar_url: params[:user][:avatar_url].presence || "https://ui-avatars.com/api/?name=User",
                                       phone_number: params[:user][:phone_number].presence || "0000000000",
                                       is_verified: true,
                                       auth_provider: "LOCAL"
                                     })

    response = HTTParty.post(BASE_URL, body: payload.to_json, headers: HEADERS)

    if response.success?
      redirect_to admin_users_path, notice: "Tạo User thành công!"
    else
      @user = User.new(user_params)
      error_msg = JSON.parse(response.body)['message'] rescue "Lỗi không xác định"
      flash.now[:alert] = "Lỗi tạo user: #{error_msg}"
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    @user = User.new(user_params)
    flash.now[:alert] = "Lỗi kết nối: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  # --- 6. UPDATE (ĐÃ FIX: Gửi đúng định dạng Java cần) ---
  def update
    id = params[:id]
    payload = user_params.to_h

    # Xử lý Verified (Kích hoạt)
    if user_params.key?(:is_verified)
      bool_verified = user_params[:is_verified].to_s == 'true'
      payload['isVerified'] = bool_verified
      payload['is_verified'] = bool_verified
    end

    # Xử lý Active (Khóa)
    if user_params.key?(:is_active)
      bool_active = user_params[:is_active].to_s == 'true'
      payload['isActive'] = bool_active
      payload['is_active'] = bool_active
    end

    response = HTTParty.put("#{BASE_URL}/#{id}", body: payload.to_json, headers: HEADERS)

    if response.success?
      # Redirect về Show để thấy kết quả ngay
      redirect_to admin_user_path(id), notice: "Cập nhật thành công!"
    else
      @user = User.find(id)
      @user.assign_attributes(user_params)
      flash.now[:alert] = "Lỗi cập nhật API: #{response.code}"
      render :edit, status: :unprocessable_entity
    end
  end

  # --- 7. DESTROY ---
  def destroy
    response = HTTParty.delete("#{BASE_URL}/#{params[:id]}", headers: HEADERS)
    if response.success?
      redirect_to admin_users_path, notice: "Đã xóa/khóa người dùng!"
    else
      redirect_to admin_users_path, alert: "Không thể xóa: #{response.code}"
    end
  end

  private

  def user_params
    permitted = params.require(:user).permit(
      :name, :email, :username, :is_active, :role,
      :phone_number, :avatar_url, :rank,
      :is_verified # Quan trọng
    )
    permitted[:role] = permitted[:role].to_i if permitted[:role].present?
    permitted
  end

  def handle_api_error(response)
    @users = []
    @total_pages = 1
    @current_page = 1
    flash.now[:alert] = "Lỗi API Java: #{response.code}"
  end

  def handle_connection_error(e)
    @users = []
    @total_pages = 1
    flash.now[:alert] = "Không kết nối được Java Backend. Hãy kiểm tra server."
    Rails.logger.error e.message
  end
end