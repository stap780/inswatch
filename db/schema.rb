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

ActiveRecord::Schema[8.1].define(version: 2025_11_11_163626) do
  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "blocked"
    t.string "charge_status"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "insales_api_password"
    t.integer "insales_charge_id"
    t.string "insales_id"
    t.boolean "installed", default: false, null: false
    t.datetime "last_login_at"
    t.decimal "monthly", precision: 10, scale: 2
    t.date "paid_till"
    t.string "password_digest", null: false
    t.string "shop"
    t.date "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["insales_charge_id"], name: "index_users_on_insales_charge_id"
    t.index ["insales_id"], name: "index_users_on_insales_id", unique: true
    t.index ["shop"], name: "index_users_on_shop"
  end

  add_foreign_key "sessions", "users"
end
