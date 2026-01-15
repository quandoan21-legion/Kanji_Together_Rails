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
    if params[:kanji_id].present?
      @kanji = Kanji.find(params[:kanji_id])
      @stories = @kanji.stories.order(created_at: :desc).page(params[:page])
    else
      # Nếu không có (truy cập bình thường), hiện tất cả như cũ
      @stories = Story.all.order(created_at: :desc).page(params[:page])
    end
    # 3. Giữ nguyên lọc theo Email
    if params[:email].present?
      @stories = @stories.where("users.email LIKE ?", "%#{params[:email]}%")
    end

    # 4. Sắp xếp theo ngày mới nhất
    @stories = @stories.order(created_at: :desc)
  end
  def show
    @story = Story.find(params[:id])
    # Thêm dòng này:
    @current_kanji = Kanji.find_by(character: @story.title)
  end

  def approve
    ActiveRecord::Base.transaction do
      @story.update!(status: :approved)

      # 1. Tìm hoặc tạo Kanji gốc
      kanji = Kanji.find_or_initialize_by(character: @story.title)

      # 2. Cập nhật thông tin chuẩn do Admin điền từ form
      kanji.assign_attributes(
        translation: params[:translation],
        meaning: params[:meaning],
        onyomi: params[:onyomi],
        kunyomi: params[:kunyomi],
        jlpt_level: params[:jlpt_level],
        stroke_count: params[:stroke_count],
        writing_image_url: params[:writing_image_url],
        radical: params[:radical],
        components: params[:components],
        kanji_story: params[:kanji_story],
        example_sentences: params[:example_sentences],
        examples: params[:examples]
      )

      # Nếu Kanji chưa có câu chuyện chính, lấy cái này làm chính
      kanji.kanji_story = @story.definition if kanji.kanji_story.blank?
      kanji.save!

      # 3. QUAN TRỌNG: Gắn bài đóng góp này vào Kanji
      @story.update!(kanji_id: kanji.id)
    end

    redirect_to admin_stories_path, notice: "Đã duyệt đóng góp mới cho chữ #{@story.title}!"
  rescue => e
    redirect_to admin_story_path(@story), alert: "Lỗi: #{e.message}"
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