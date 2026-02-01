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
  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.string "name"
  end

  create_table "categories_rel_kanji_stories", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "kanji_story_id", null: false
    t.index ["category_id"], name: "FK9xgomt3u6712otbrgkji2ulrg"
    t.index ["kanji_story_id"], name: "FKc0kui7fnn6cddaqs80f3dxhs1"
  end

  create_table "categories_rel_users", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "FKt19h038lg5co3rn0twrup93x9"
    t.index ["user_id"], name: "FKn0f0rpoyuw9ff8cr5gg2q2me3"
  end

  create_table "clazz", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.string "description", limit: 500
    t.datetime "edit_at"
    t.boolean "is_active", default: true
    t.string "name", limit: 100, null: false
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.column "category", "enum('GENERAL','GRAMMAR','JLPT','KANJI','VOCAB')", null: false
    t.string "cover_image_url"
    t.datetime "create_at"
    t.text "description"
    t.datetime "edit_at"
    t.string "name", null: false
    t.string "thumbnail_url"
    t.string "time_to_finish", null: false
  end

  create_table "exam_attempt_answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "answered_at"
    t.bigint "exam_result_id"
    t.binary "is_correct", limit: 1
    t.bigint "question_id"
    t.integer "selected_answer_id"
    t.bigint "time_taken_ms"
    t.bigint "user_id"
    t.index ["exam_result_id"], name: "FKb0qfdgdgmpkla4b4quskxi4eh"
    t.index ["question_id"], name: "FKdvthxuq5nobdahc5wg5jw3prf"
    t.index ["user_id"], name: "FKjyhwrg80l0ko4ahglv5ghc0eg"
  end

  create_table "exam_lessons", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.bigint "lesson_id", null: false
    t.index ["exam_id"], name: "FK5y326kyijsfxqwh1hcjx1ijti"
    t.index ["lesson_id"], name: "FKd9gxb3jmd6xbyj8h2cwch0cpp"
  end

  create_table "exam_questions", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.bigint "question_id", null: false
    t.index ["exam_id"], name: "FK5cd6sjmccb11rrwpyabyc81c0"
    t.index ["question_id"], name: "FKs0t1710in6q97whp93ggrs1wg"
  end

  create_table "exam_results", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "correct_answer"
    t.datetime "create_at"
    t.bigint "exam_id"
    t.integer "total_question"
    t.bigint "user_id"
    t.index ["exam_id"], name: "FKtf85ht7yquiorwjx2xbdx3fxw"
    t.index ["user_id"], name: "FKt2jcn29o332cpiv7s7h3o877e"
  end

  create_table "exams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.integer "duration"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.bigint "lesson_id"
    t.string "name", null: false
    t.integer "pass_score"
    t.integer "status"
    t.string "target_rank"
    t.integer "total_questions"
    t.column "type", "enum('ENTRANCE','MINI','SKIBIDI','SUPER','DAILY')"
  end

  create_table "friend", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.bigint "friend_id"
    t.bigint "user_id"
    t.index ["friend_id"], name: "FK5j28qgyvon52ycu9sfieraerm"
    t.index ["user_id"], name: "FKeab81424e9dtc4a8hjlq4xiew"
  end

  create_table "kanji_characters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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
    t.string "status"
    t.string "translation"
    t.text "vocabulary"
    t.string "writing_image_url"
    t.index ["kanji"], name: "UK4jrmio96ladmsnxmjqeqyc26s", unique: true
  end

  create_table "kanji_characters_rel_lesson", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.bigint "lesson_id", null: false
    t.index ["kanji_id"], name: "FKq9fifesb1d5q09mktpefms0bq"
    t.index ["lesson_id"], name: "FKiv99t78m5h7y0596yoka5awp5"
  end

  create_table "kanji_characters_rel_question", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.bigint "question_id", null: false
    t.index ["kanji_id"], name: "FK4n2v7wu1ck8eck3dpirucpw7y"
    t.index ["question_id"], name: "FK8pw4i6mgfddlc1dkwnpc3dqcn"
  end

  create_table "kanji_lessons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "JLPT"
    t.bigint "course_id"
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.string "kanji", limit: 50
    t.string "lesson_description"
    t.string "name"
    t.string "status"
    t.index ["course_id"], name: "FKkg932ecvbwmtluonl3flc5x9c"
  end

  create_table "kanji_stories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.binary "is_active", limit: 1
    t.bigint "kanji_id", null: false
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

  create_table "kanji_stories_ai", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.string "jlpt_level"
    t.string "kanji"
    t.string "meaning"
    t.text "story"
  end

  create_table "notification_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "create_at"
    t.datetime "edit_at"
    t.text "error_message"
    t.string "fcm_token", null: false
    t.string "kanji_hash", limit: 64, null: false
    t.text "kanji_ids", null: false
    t.column "status", "enum('FAILED','PENDING','SENT')", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "FKsbx1lf2w8tr7siwwibcj9k3fg"
  end

  create_table "question_answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "answer"
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.binary "is_correct_answer", limit: 1
    t.bigint "question_id"
    t.index ["question_id"], name: "FKrms3u35c10orgjqyw03ajd7x7"
  end

  create_table "questions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "correct_answer", null: false
    t.datetime "create_at"
    t.integer "create_by"
    t.datetime "edit_at"
    t.integer "edit_by"
    t.bigint "exam_id"
    t.string "name"
    t.string "question"
    t.text "question_text"
    t.string "question_type", null: false
    t.integer "status", null: false
    t.string "wrong_answer_1", null: false
    t.string "wrong_answer_2", null: false
    t.string "wrong_answer_3", null: false
    t.index ["exam_id"], name: "FKrk78bmt53fns7np8casqa3q44"
  end

  create_table "subscription_plans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "transactions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "user_device_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "app_version", limit: 50
    t.datetime "create_at"
    t.string "device_id"
    t.datetime "edit_at"
    t.string "fcm_token", null: false
    t.binary "is_active", limit: 1
    t.datetime "last_seen_at"
    t.string "platform", limit: 20
    t.bigint "user_id", null: false
    t.index ["fcm_token"], name: "UK8m3wt56wj3c1osfh3wo3mah7f", unique: true
    t.index ["user_id"], name: "FKevk16cemgy1bwx5s0d6oa8x41"
  end

  create_table "user_email_otps", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "attempts", null: false
    t.string "code_hash", null: false
    t.datetime "consumed_at"
    t.datetime "expires_at", null: false
    t.datetime "last_sent_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "FKflfd39qjdatlq748wn4bosmwx"
  end

  create_table "user_kanji_attempts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "answered_at", null: false
    t.binary "is_correct", limit: 1, null: false
    t.bigint "kanji_id", null: false
    t.bigint "question_attempt_id", null: false
    t.bigint "user_id", null: false
    t.index ["kanji_id"], name: "FKa84sjmf99636cb963snwsat41"
    t.index ["question_attempt_id"], name: "FKahwyajlf5a2cka9d90m8sytwj"
    t.index ["user_id", "answered_at"], name: "idx_uka_user_answered_at"
    t.index ["user_id", "kanji_id"], name: "idx_uka_user_kanji"
  end

  create_table "user_kanji_mastery", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.float "ease_factor", limit: 53, null: false
    t.integer "interval_days", null: false
    t.bigint "kanji_id", null: false
    t.datetime "last_attempt_at"
    t.datetime "last_correct_at"
    t.integer "mastery_level", null: false
    t.datetime "next_review_at", null: false
    t.integer "repetitions", null: false
    t.integer "total_correct", null: false
    t.integer "total_wrong", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["kanji_id"], name: "FK16i0ovbw1c0rej81m7nwv7m6s"
    t.index ["user_id", "kanji_id"], name: "uk_user_kanji", unique: true
    t.index ["user_id", "next_review_at"], name: "idx_ukm_user_next_review"
  end

  create_table "user_question_attempts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "answered_at", null: false
    t.binary "is_correct", limit: 1, null: false
    t.bigint "question_id", null: false
    t.string "selected_answer"
    t.integer "time_spent_ms"
    t.bigint "user_id", null: false
    t.index ["question_id"], name: "FK64dbonuwv85vwa4jbkehxybkk"
    t.index ["user_id", "answered_at"], name: "idx_uqa_user_answered_at"
  end

  create_table "user_subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "end_at"
    t.bigint "plan_id"
    t.datetime "start_at"
    t.column "status", "enum('ACTIVE','CANCELLED','EXPIRED','FAILED','PENDING','SUCCESS')"
    t.bigint "user_id"
    t.index ["plan_id"], name: "FKgvwf73xtk31h777lq0wvk7u0w"
    t.index ["user_id"], name: "FK3l40lbyji8kj5xoc20ycwsc8g"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "address_line1"
    t.string "auth_provider"
    t.string "avatar_url", null: false
    t.string "city"
    t.bigint "clazz_id"
    t.string "country"
    t.datetime "create_by"
    t.string "display_name", null: false
    t.datetime "edit_at"
    t.datetime "edit_by"
    t.string "email", null: false
    t.binary "has_entrance_exam", limit: 1
    t.binary "have_daily_exam", limit: 1
    t.binary "is_active", limit: 1
    t.binary "is_verified", limit: 1
    t.datetime "last_login_at"
    t.string "name", null: false
    t.string "password_hash"
    t.string "phone_number", null: false
    t.string "postal_code"
    t.string "rank"
    t.integer "role", default: 0, null: false
    t.datetime "start_date"
    t.string "state"
    t.string "username", null: false
    t.index ["clazz_id"], name: "FKkiqo4jp9gc0klvw5pqo8w6fs6"
    t.index ["email"], name: "UK6dotkott2kjsp8vw4d0m25fb7", unique: true
    t.index ["username"], name: "UKr43af9ap4edm43mmtq01oddj6", unique: true
  end

  add_foreign_key "categories_rel_kanji_stories", "categories", name: "FK9xgomt3u6712otbrgkji2ulrg"
  add_foreign_key "categories_rel_kanji_stories", "kanji_stories", name: "FKc0kui7fnn6cddaqs80f3dxhs1"
  add_foreign_key "categories_rel_users", "categories", name: "FKt19h038lg5co3rn0twrup93x9"
  add_foreign_key "categories_rel_users", "users", name: "FKn0f0rpoyuw9ff8cr5gg2q2me3"
  add_foreign_key "exam_attempt_answers", "exam_results", name: "FKb0qfdgdgmpkla4b4quskxi4eh"
  add_foreign_key "exam_attempt_answers", "questions", name: "FKdvthxuq5nobdahc5wg5jw3prf"
  add_foreign_key "exam_attempt_answers", "users", name: "FKjyhwrg80l0ko4ahglv5ghc0eg"
  add_foreign_key "exam_lessons", "exams", name: "FK5y326kyijsfxqwh1hcjx1ijti"
  add_foreign_key "exam_lessons", "kanji_lessons", column: "lesson_id", name: "FKd9gxb3jmd6xbyj8h2cwch0cpp"
  add_foreign_key "exam_questions", "exams", name: "FK5cd6sjmccb11rrwpyabyc81c0"
  add_foreign_key "exam_questions", "questions", name: "FKs0t1710in6q97whp93ggrs1wg"
  add_foreign_key "exam_results", "exams", name: "FKtf85ht7yquiorwjx2xbdx3fxw"
  add_foreign_key "exam_results", "users", name: "FKt2jcn29o332cpiv7s7h3o877e"
  add_foreign_key "friend", "users", column: "friend_id", name: "FK5j28qgyvon52ycu9sfieraerm"
  add_foreign_key "friend", "users", name: "FKeab81424e9dtc4a8hjlq4xiew"
  add_foreign_key "kanji_characters_rel_lesson", "kanji_characters", column: "kanji_id", name: "FKq9fifesb1d5q09mktpefms0bq"
  add_foreign_key "kanji_characters_rel_lesson", "kanji_lessons", column: "lesson_id", name: "FKiv99t78m5h7y0596yoka5awp5"
  add_foreign_key "kanji_characters_rel_question", "kanji_characters", column: "kanji_id", name: "FK4n2v7wu1ck8eck3dpirucpw7y"
  add_foreign_key "kanji_characters_rel_question", "questions", name: "FK8pw4i6mgfddlc1dkwnpc3dqcn"
  add_foreign_key "kanji_lessons", "courses", name: "FKkg932ecvbwmtluonl3flc5x9c"
  add_foreign_key "kanji_stories", "kanji_characters", column: "kanji_id", name: "FKguagfg3ct1k9jr09p74nlafn9"
  add_foreign_key "kanji_stories", "users", name: "FKi5c7ag29p6nkrk1gnlga5oxac"
  add_foreign_key "notification_logs", "users", name: "FKsbx1lf2w8tr7siwwibcj9k3fg"
  add_foreign_key "question_answers", "questions", name: "FKrms3u35c10orgjqyw03ajd7x7"
  add_foreign_key "questions", "exams", name: "FKrk78bmt53fns7np8casqa3q44"
  add_foreign_key "transactions", "subscription_plans", column: "plan_id", name: "FKdf7liw2trs7xoipc6nekx8fet"
  add_foreign_key "transactions", "users", name: "FKqwv7rmvc8va8rep7piikrojds"
  add_foreign_key "user_device_tokens", "users", name: "FKevk16cemgy1bwx5s0d6oa8x41"
  add_foreign_key "user_email_otps", "users", name: "FKflfd39qjdatlq748wn4bosmwx"
  add_foreign_key "user_kanji_attempts", "kanji_characters", column: "kanji_id", name: "FKa84sjmf99636cb963snwsat41"
  add_foreign_key "user_kanji_attempts", "user_question_attempts", column: "question_attempt_id", name: "FKahwyajlf5a2cka9d90m8sytwj"
  add_foreign_key "user_kanji_attempts", "users", name: "FK7t68kba4ykarollvrdlg3l3nj"
  add_foreign_key "user_kanji_mastery", "kanji_characters", column: "kanji_id", name: "FK16i0ovbw1c0rej81m7nwv7m6s"
  add_foreign_key "user_kanji_mastery", "users", name: "FK1wk1l2w9enl9sm6cg4qur7pjc"
  add_foreign_key "user_question_attempts", "questions", name: "FK64dbonuwv85vwa4jbkehxybkk"
  add_foreign_key "user_question_attempts", "users", name: "FKm1ajavvc1tkgvrpf52mgk8aiv"
  add_foreign_key "user_subscriptions", "subscription_plans", column: "plan_id", name: "FKgvwf73xtk31h777lq0wvk7u0w"
  add_foreign_key "user_subscriptions", "users", name: "FK3l40lbyji8kj5xoc20ycwsc8g"
  add_foreign_key "users", "clazz", name: "FKkiqo4jp9gc0klvw5pqo8w6fs6"
end
