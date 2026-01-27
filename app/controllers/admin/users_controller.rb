# frozen_string_literal: true

class UsersController
  def index
    is_active = case params[:status]
                when 'ACTIVE' then true
                when 'BANNED' then false
                else nil
                end

    query_params = {
      name: params[:keyword], email: params[:keyword],
      active: is_active, page: (params[:page] || 1).to_i - 1, size: 10
    }

    response = HTTParty.get("#{BASE_URL}/api/v1/users", query: query_params)
    if response.success?
      res = JSON.parse(response.body)['data']
      @users = res['content']
      @total_pages = res['totalPages']
      @current_page = res['number'] + 1
    end
  end
  def show
    response = HTTParty.get("#{BASE_URL}/api/v1/users/#{params[:id]}", headers: API_HEADERS)

    if response.success?
      @user = JSON.parse(response.body)['data']
    else
      redirect_to admin_users_path, alert: "Không tìm thấy người dùng này!"
    end
  end
  def create
    response = HTTParty.post("#{BASE_URL}/api/v1/users", body: user_params.to_json, headers: API_HEADERS)
    if response.code == 201
      redirect_to admin_users_path, notice: "Tạo User thành công!"
    else
      flash[:alert] = "Lỗi tạo User"
      render :new
    end
  end

  def update
    response = HTTParty.put("#{BASE_URL}/api/v1/users/#{params[:id]}", body: user_params.to_json, headers: API_HEADERS)
    redirect_to admin_users_path, notice: "Cập nhật thành công!" if response.success?
  end

  def destroy
    HTTParty.delete("#{BASE_URL}/api/v1/users/#{params[:id]}")
    redirect_to admin_users_path, notice: "Đã khóa người dùng!"
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :username, :isActive, :rank)
  end
end
