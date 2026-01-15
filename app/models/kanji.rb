class Kanji < ApplicationRecord
  before_validation :strip_whitespace
  # Định nghĩa Regex: Chỉ chấp nhận các ký tự trong dải Unicode của Kanji
  VALID_KATAKANA_REGEX = /\A\s*[\u30a0-\u30ff]+\s*\z/
  VALID_HIRAGANA_REGEX = /\A\s*[\u3040-\u309f]+\s*\z/
  VALID_KANJI_REGEX = /\A\s*[\u4e00-\u9faf]+\s*\z/

  validates :character, presence: true,
            format: { with: VALID_KANJI_REGEX, message: "chỉ được phép nhập chữ Hán (Kanji)" },
            uniqueness: { message: "đã tồn tại trong hệ thống" }

  # 1. Âm On (Onyomi): Bắt buộc phải là Katakana
  validates :onyomi , allow_blank: true,
            format: {
              with: VALID_KATAKANA_REGEX,
              message: "bắt buộc phải nhập bằng chữ Katakana (ví dụ: ニチ)"
            }

  # 2. Âm Kun (Kunyomi): Bắt buộc phải là Hiragana
  validates :kunyomi, allow_blank: true,
            format: {
              with: VALID_HIRAGANA_REGEX,
              message: "bắt buộc phải nhập bằng chữ Hiragana (ví dụ: ひ)"
            }
  private

  # Hàm xử lý cắt bỏ khoảng trắng thừa
  def strip_whitespace
    self.character = character.strip if character.present?
    self.onyomi = onyomi.strip if onyomi.present?
    self.kunyomi = kunyomi.strip if kunyomi.present?
  end
  validates :meaning, :translation, presence: true
  validates :jlpt_level, inclusion: { in: 1..5 }, allow_nil: true
end