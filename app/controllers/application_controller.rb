class ApplicationController < ActionController::Base
  # Chỉ yêu cầu đăng nhập đối với các trang không thuộc Devise
  before_action :authenticate_admin!, unless: :devise_controller?

  allow_browser versions: :modern
  stale_when_importmap_changes

  # Cấu hình Layout riêng
  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller?
      "devise" # File layout này chúng ta sẽ tạo ở bước 2
    else
      "application"
    end
  end
end