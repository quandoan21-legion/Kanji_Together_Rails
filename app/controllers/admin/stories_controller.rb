# app/controllers/admin/stories_controller.rb
class Admin::StoriesController < ApplicationController
  # SỬA DÒNG NÀY: Chỉ chạy set_story cho các hàm đang có bên dưới
  before_action :set_story, only: [:show, :approve, :reject]
  before_action :authenticate_admin!
  # app/controllers/admin/stories_controller.rb
  def index
    @stories = Story.includes(:user).joins(:user)

    # Lọc theo trạng thái (nếu có)
    @stories = @stories.where(status: params[:status]) if params[:status].present?

    # Lọc theo Email (Phần gây lỗi nếu thiếu .joins(:user))
    if params[:email].present?
      @stories = @stories.where("users.email LIKE ?", "%#{params[:email]}%")
    end

    # Sắp xếp theo ngày mới nhất
    @stories = @stories.order(created_at: :desc)
  end

  def show
    # @story đã được set bởi before_action
  end

  def approve
    # Sử dụng transaction để đảm bảo cả 2 việc: cập nhật Story và ghi Log đều thành công
    ActiveRecord::Base.transaction do
      @story.update!(status: :approved, rejection_reason: nil)

      # Ghi log (Giả sử current_user là Admin đang đăng nhập)
      ReviewAuditLog.create!(
        story: @story,
        admin: current_user, # Hoặc User.find_by(role: :admin) nếu chưa có hệ thống login
        action: "approve"
      )
    end
    redirect_to admin_story_path(@story), notice: "Phê duyệt thành công và đã ghi log."
  end

  def reject
    ActiveRecord::Base.transaction do
      @story.update!(status: :rejected, rejection_reason: params[:rejection_reason])

      ReviewAuditLog.create!(
        story: @story,
        admin: current_user,
        action: "reject",
        reason: params[:rejection_reason]
      )
    end
    redirect_to admin_story_path(@story), notice: "Đã từ chối và ghi lý do vào log."
  end

  private

  def set_story
    @story = Story.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_stories_path, alert: "Không tìm thấy bài viết."
  end
  def authenticate_admin!
    unless current_user&.role == "admin" || current_user&.admin?
      redirect_to root_path, alert: "Chỉ Admin mới có quyền vào đây!"
    end
  end

  # Giả lập current_user nếu bạn chưa làm chức năng Login
  # Sau này khi có Login xóa hàm này đi
  def current_user
    @current_user ||= User.find_by(role: :admin) # Lấy tạm 1 admin trong DB để test
  end
end