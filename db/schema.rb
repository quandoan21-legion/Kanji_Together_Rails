# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_14_113504) do
  create_table "kanjis", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "character"
    t.string "components"
    t.datetime "created_at", null: false
    t.text "example_sentences"
    t.text "examples"
    t.integer "jlpt_level"
    t.text "kanji_story"
    t.string "kunyomi"
    t.text "meaning"
    t.string "onyomi"
    t.string "radical"
    t.integer "stroke_count"
    t.string "translation"
    t.datetime "updated_at", null: false
    t.string "writing_image_url"
    t.index ["character"], name: "index_kanjis_on_character"
  end
end
