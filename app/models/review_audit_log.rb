class ReviewAuditLog < ApplicationRecord
  belongs_to :story
  belongs_to :admin, class_name: 'User', foreign_key: 'admin_id'
end