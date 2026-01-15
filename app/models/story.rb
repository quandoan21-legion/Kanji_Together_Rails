class Story < ApplicationRecord
  # Quan hệ (Associations)
  belongs_to :user # Kết nối với bảng users từ Spring Boot
  has_many :review_audit_logs, dependent: :destroy # Lưu lịch sử duyệt bài

  # [AC8] Quản lý trạng thái: 0: Chờ, 1: Duyệt, 2: Từ chối
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  # Ràng buộc dữ liệu (Validations)
  validates :title, :definition, presence: true
  # [AC4] Bắt buộc có lý do khi từ chối
  validates :rejection_reason, presence: true, if: :rejected?

  # [AC9] Bộ lọc cho Admin
  scope :pending_review, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }

  # [AC7] Quyền chỉnh sửa: User chỉ sửa được khi bài chưa duyệt hoặc bị từ chối
  def editable_by?(user_account)
    return false unless user_account
    user_id == user_account.id && (pending? || rejected?)
  end
end