class Kanji < ApplicationRecord
  # AC: Không cho tạo Kanji trùng character
  validates :character, presence: true, uniqueness: { message: "đã tồn tại trong hệ thống" }
  validates :meaning, :translation, presence: true
  validates :jlpt_level, inclusion: { in: 1..5 }, allow_nil: true
end