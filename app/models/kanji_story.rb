class KanjiStory < ApplicationRecord
  self.table_name = 'kanji_stories'
  
  has_many :review_audit_logs
  
  validates :kanji_text, presence: true
  
  scope :active, -> { where(is_active: true) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_kanji, ->(kanji) { where(kanji_text: kanji) if kanji.present? }
  scope :by_kanji_id, ->(kanji_id) { where(kanji_id: kanji_id) if kanji_id.present? }
end
