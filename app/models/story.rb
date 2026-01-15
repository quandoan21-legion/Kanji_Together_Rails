class Story < ApplicationRecord
  # Định nghĩa Regex để chỉ chấp nhận các ký tự Kanji (chữ Hán)
  VALID_KANJI_REGEX = /\A[\u4e00-\u9faf]+\z/

  # Quan hệ (Associations)
  belongs_to :user
  has_many :review_audit_logs, dependent: :destroy
  belongs_to :kanji, optional: true

  # Quản lý trạng thái
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  # Ràng buộc dữ liệu (Validations)
  # SỬA TẠI ĐÂY: Thêm kiểm tra định dạng cho :title để chỉ cho phép chữ Hán
  validates :title, presence: true,
            format: { with: VALID_KANJI_REGEX, message: "chỉ được phép nhập chữ Hán (Kanji)" }

  validates :definition, presence: true

  # Bắt buộc có lý do khi từ chối
  validates :rejection_reason, presence: true, if: :rejected?

  # Bộ lọc cho Admin
  scope :pending_review, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }

  # [AC7] Quyền chỉnh sửa
  def editable_by?(user_account)
    return false unless user_account
    user_id == user_account.id && (pending? || rejected?)
  end
end