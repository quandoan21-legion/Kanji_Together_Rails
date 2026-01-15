class User < ApplicationRecord
  has_many :stories
  has_many :review_audit_logs, foreign_key: :admin_id
  enum :role, { user: 0, admin: 1 }, default: :user
end