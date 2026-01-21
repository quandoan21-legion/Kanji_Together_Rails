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

ActiveRecord::Schema[8.1].define(version: 2026_01_21_093658) do
  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.string "name"
  end

  create_table "categories_rel_kanji_stories", id: false, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "kanji_story_id", null: false
    t.index ["category_id"], name: "FK9xgomt3u6712otbrgkji2ulrg"
    t.index ["kanji_story_id"], name: "FKc0kui7fnn6cddaqs80f3dxhs1"
  end

  create_table "categories_rel_users", id: false, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "FKt19h038lg5co3rn0twrup93x9"
    t.index ["user_id"], name: "FKn0f0rpoyuw9ff8cr5gg2q2me3"
  end

  create_table "clazz", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.string "description", limit: 500
    t.datetime "edit_at"
    t.integer "edit_by"
    t.boolean "is_active", default: true
    t.string "name", limit: 100, null: false
  end

  create_table "clazz_rel_users", id: false, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "clazz_id", null: false
    t.bigint "user_id", null: false
    t.index ["clazz_id"], name: "FK5r6ip0dnjaycy3lcx90h60dab"
    t.index ["user_id"], name: "FK9c6c14mqa4hg41acwhtbk8xe2"
  end

  create_table "exam_attempt_answers", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "answered_at"
    t.bigint "exam_result_id"
    t.binary "is_correct", limit: 1
    t.bigint "question_id"
    t.integer "selected_answer_id"
    t.index ["exam_result_id"], name: "FKb0qfdgdgmpkla4b4quskxi4eh"
    t.index ["question_id"], name: "FKdvthxuq5nobdahc5wg5jw3prf"
  end

  create_table "exam_results", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "correct_answer"
    t.datetime "create_at"
    t.bigint "exam_id"
    t.integer "total_question"
    t.bigint "user_id"
    t.index ["exam_id"], name: "FKtf85ht7yquiorwjx2xbdx3fxw"
    t.index ["user_id"], name: "FKt2jcn29o332cpiv7s7h3o877e"
  end

  create_table "exams", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.column "exam_type", "enum('ENTRANCE_EXAM','MOCK_TEST','PRACTICE')"
    t.string "name", null: false
    t.string "question"
  end

  create_table "friend", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.bigint "friend_id"
    t.bigint "user_id"
    t.index ["friend_id"], name: "FK5j28qgyvon52ycu9sfieraerm"
    t.index ["user_id"], name: "FKeab81424e9dtc4a8hjlq4xiew"
  end

  create_table "kanji_characters", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "JLPT"
    t.string "components"
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.text "examples"
    t.binary "is_active", limit: 1
    t.string "kanji", limit: 10, null: false
    t.string "kanji_description"
    t.string "kun_pronunciation"
    t.text "meaning"
    t.integer "num_strokes"
    t.string "on_pronunciation"
    t.string "radical"
    t.string "translation"
    t.text "vocabulary"
    t.string "writing_image_url"
    t.index ["kanji"], name: "UK4jrmio96ladmsnxmjqeqyc26s", unique: true
  end

  create_table "kanji_characters_rel_lesson", id: false, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.bigint "lesson_id", null: false
    t.index ["kanji_id"], name: "FKq9fifesb1d5q09mktpefms0bq"
    t.index ["lesson_id"], name: "FKiv99t78m5h7y0596yoka5awp5"
  end

  create_table "kanji_characters_rel_question", id: false, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.bigint "question_id", null: false
    t.index ["kanji_id"], name: "FK4n2v7wu1ck8eck3dpirucpw7y"
    t.index ["question_id"], name: "FK8pw4i6mgfddlc1dkwnpc3dqcn"
  end

  create_table "kanji_lessons", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "JLPT"
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.string "kanji", limit: 10
    t.string "lesson_description"
    t.string "name"
  end

  create_table "kanji_stories", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.binary "is_active", limit: 1
    t.bigint "kanji_id"
    t.integer "kanji_int"
    t.string "kanji_stories"
    t.string "kanji_story"
    t.string "kanji_text"
    t.text "reject_reason"
    t.string "status"
    t.string "user_components"
    t.text "user_examples"
    t.bigint "user_id"
    t.string "user_kunyomi"
    t.string "user_meaning"
    t.integer "user_num_strokes"
    t.string "user_onyomi"
    t.string "user_radical"
    t.string "user_translation"
    t.text "user_vocabulary"
    t.index ["kanji_id"], name: "FKguagfg3ct1k9jr09p74nlafn9"
    t.index ["user_id"], name: "FKi5c7ag29p6nkrk1gnlga5oxac"
  end

  create_table "kanji_stories_ai", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.string "jlpt_level"
    t.string "kanji"
    t.string "meaning"
    t.text "story"
  end

  create_table "question_answers", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "answer"
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.binary "is_correct_answer", limit: 1
    t.bigint "question_id"
    t.index ["question_id"], name: "FKrms3u35c10orgjqyw03ajd7x7"
  end

  create_table "questions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.bigint "exam_id"
    t.integer "kanji_related_id"
    t.string "name"
    t.string "question"
    t.column "question_type", "enum('FILL_IN_BLANK','MATCHING','MULTIPLE_CHOICE')"
    t.index ["exam_id"], name: "FKrk78bmt53fns7np8casqa3q44"
  end

  create_table "subscription_plans", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.column "billing_period", "enum('MONTHLY','ONE_TIME','YEARLY')"
    t.string "code"
    t.datetime "create_at"
    t.string "currency", limit: 3
    t.datetime "edit_at"
    t.binary "is_active", limit: 1
    t.string "name"
    t.integer "period_value"
    t.decimal "price", precision: 38, scale: 2
  end

  create_table "transactions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.decimal "amount", precision: 38, scale: 2
    t.datetime "created_at"
    t.string "currency", limit: 3
    t.datetime "paid_at"
    t.bigint "plan_id"
    t.column "provider", "enum('BANK_TRANSFER','PAYPAL','STRIPE')"
    t.string "provider_txn_id"
    t.column "status", "enum('ACTIVE','CANCELLED','EXPIRED','FAILED','PENDING','SUCCESS')"
    t.bigint "user_id"
    t.index ["plan_id"], name: "FKdf7liw2trs7xoipc6nekx8fet"
    t.index ["user_id"], name: "FKqwv7rmvc8va8rep7piikrojds"
  end

  create_table "user_subscriptions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "end_at"
    t.bigint "plan_id"
    t.datetime "start_at"
    t.column "status", "enum('ACTIVE','CANCELLED','EXPIRED','FAILED','PENDING','SUCCESS')"
    t.bigint "user_id"
    t.index ["plan_id"], name: "FKgvwf73xtk31h777lq0wvk7u0w"
    t.index ["user_id"], name: "FK3l40lbyji8kj5xoc20ycwsc8g"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "clazz_id"
    t.datetime "create_by"
    t.datetime "edit_at"
    t.datetime "edit_by"
    t.string "email", null: false
    t.binary "has_entrance_exam", limit: 1
    t.binary "is_active", limit: 1
    t.binary "is_verified", limit: 1
    t.string "name", null: false
    t.index ["clazz_id"], name: "FKkiqo4jp9gc0klvw5pqo8w6fs6"
    t.index ["email"], name: "UK6dotkott2kjsp8vw4d0m25fb7", unique: true
  end

  add_foreign_key "categories_rel_kanji_stories", "categories", name: "FK9xgomt3u6712otbrgkji2ulrg"
  add_foreign_key "categories_rel_kanji_stories", "kanji_stories", name: "FKc0kui7fnn6cddaqs80f3dxhs1"
  add_foreign_key "categories_rel_users", "categories", name: "FKt19h038lg5co3rn0twrup93x9"
  add_foreign_key "categories_rel_users", "users", name: "FKn0f0rpoyuw9ff8cr5gg2q2me3"
  add_foreign_key "clazz_rel_users", "clazz", name: "FK5r6ip0dnjaycy3lcx90h60dab"
  add_foreign_key "clazz_rel_users", "users", name: "FK9c6c14mqa4hg41acwhtbk8xe2"
  add_foreign_key "exam_attempt_answers", "exam_results", name: "FKb0qfdgdgmpkla4b4quskxi4eh"
  add_foreign_key "exam_attempt_answers", "questions", name: "FKdvthxuq5nobdahc5wg5jw3prf"
  add_foreign_key "exam_results", "exams", name: "FKtf85ht7yquiorwjx2xbdx3fxw"
  add_foreign_key "exam_results", "users", name: "FKt2jcn29o332cpiv7s7h3o877e"
  add_foreign_key "friend", "users", column: "friend_id", name: "FK5j28qgyvon52ycu9sfieraerm"
  add_foreign_key "friend", "users", name: "FKeab81424e9dtc4a8hjlq4xiew"
  add_foreign_key "kanji_characters_rel_lesson", "kanji_characters", column: "kanji_id", name: "FKq9fifesb1d5q09mktpefms0bq"
  add_foreign_key "kanji_characters_rel_lesson", "kanji_lessons", column: "lesson_id", name: "FKiv99t78m5h7y0596yoka5awp5"
  add_foreign_key "kanji_characters_rel_question", "kanji_characters", column: "kanji_id", name: "FK4n2v7wu1ck8eck3dpirucpw7y"
  add_foreign_key "kanji_characters_rel_question", "questions", name: "FK8pw4i6mgfddlc1dkwnpc3dqcn"
  add_foreign_key "kanji_stories", "kanji_characters", column: "kanji_id", name: "FKguagfg3ct1k9jr09p74nlafn9"
  add_foreign_key "kanji_stories", "users", name: "FKi5c7ag29p6nkrk1gnlga5oxac"
  add_foreign_key "question_answers", "questions", name: "FKrms3u35c10orgjqyw03ajd7x7"
  add_foreign_key "questions", "exams", name: "FKrk78bmt53fns7np8casqa3q44"
  add_foreign_key "transactions", "subscription_plans", column: "plan_id", name: "FKdf7liw2trs7xoipc6nekx8fet"
  add_foreign_key "transactions", "users", name: "FKqwv7rmvc8va8rep7piikrojds"
  add_foreign_key "user_subscriptions", "subscription_plans", column: "plan_id", name: "FKgvwf73xtk31h777lq0wvk7u0w"
  add_foreign_key "user_subscriptions", "users", name: "FK3l40lbyji8kj5xoc20ycwsc8g"
  add_foreign_key "users", "clazz", name: "FKkiqo4jp9gc0klvw5pqo8w6fs6"
end
