# app/controllers/admin/stories_controller.rb
class Admin::StoriesController < ApplicationController
  # SỬA DÒNG NÀY: Chỉ chạy set_story cho các hàm đang có bên dưới
  before_action :set_story, only: [:show, :approve, :reject]
  before_action :authenticate_admin!
  # app/controllers/admin/stories_controller.rb
  def index
    # 1. Khởi tạo query lấy dữ liệu kèm User để tránh lỗi N+1
    @stories = Story.includes(:user).joins(:user)

    # 2. Xử lý Lọc theo trạng thái (Status)
    # Nếu params[:status] có giá trị (không rỗng), ta mới thực hiện lọc
    # Nếu params[:status] rỗng (tương ứng với "Tất cả"), hệ thống sẽ lấy hết
    if params[:status].present?
      @stories = @stories.where(status: params[:status])
    end

    # 3. Giữ nguyên lọc theo Email
    if params[:email].present?
      @stories = @stories.where("users.email LIKE ?", "%#{params[:email]}%")
    end

    # 4. Sắp xếp theo ngày mới nhất
    @stories = @stories.order(created_at: :desc)
  end
  def show
  end

  def approve
    ActiveRecord::Base.transaction do
      # 1. Cập nhật Story
      @story.update!(status: :approved, rejection_reason: nil)

      # 2. Ghi nhật ký duyệt (Audit Log)
      ReviewAuditLog.create!(
        story: @story,
        admin: current_user,
        action: "approve"
      )

      # 3. ĐỒNG BỘ SANG KANJI
      kanji = Kanji.find_or_initialize_by(character: @story.title)


      kanji.meaning = "Chưa cập nhật" if kanji.meaning.blank?


      kanji.translation = "Chưa cập nhật" if kanji.translation.blank?

      # 'kanji_story' lưu nội dung câu chuyện đầy đủ
      kanji.kanji_story = @story.definition if kanji.respond_to?(:kanji_story)

      # Các cột khác
      kanji.examples = @story.example if kanji.respond_to?(:examples)
      kanji.jlpt_level = 5 if kanji.jlpt_level.nil?

      kanji.save!
    end

    redirect_to admin_story_path(@story), notice: "Duyệt thành công! Chữ '#{@story.title}' đã lên trang Quản lý."
  rescue => e
    puts "---------- LỖI DUYỆT THỰC TẾ: #{e.message} ----------"
    redirect_to admin_story_path(@story), alert: "Lỗi đồng bộ: #{e.message}"
  end
  def reject
    ActiveRecord::Base.transaction do
      # 1. Cập nhật trạng thái Story thành Rejected
      @story.update!(status: :rejected, rejection_reason: params[:rejection_reason])

      # 2. Ghi nhật ký duyệt (Audit Log)
      ReviewAuditLog.create!(
        story: @story,
        admin: current_user,
        action: "reject",
        reason: params[:rejection_reason]
      )

      # Tìm Kanji dựa trên chữ (character) và xóa nó đi
      kanji = Kanji.find_by(character: @story.title)
      kanji.destroy if kanji.present?
    end

    redirect_to admin_stories_path, notice: "Đã từ chối chữ '#{@story.title}'"
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
    @current_user ||= User.find_by(role: :admin)
  end
end