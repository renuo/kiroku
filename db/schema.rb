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

ActiveRecord::Schema[8.1].define(version: 2026_02_24_112903) do
  create_table "receipts", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "file"
    t.datetime "recorded_on"
    t.date "spent_on"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["code"], name: "index_receipts_on_code"
    t.index ["recorded_on"], name: "index_receipts_on_recorded_on"
    t.index ["spent_on"], name: "index_receipts_on_spent_on"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid"
    t.string "name", null: false
    t.string "slack_uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["slack_uid"], name: "index_users_on_slack_uid", unique: true
  end

  add_foreign_key "receipts", "users"
end
