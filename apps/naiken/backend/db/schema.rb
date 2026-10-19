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

ActiveRecord::Schema[8.1].define(version: 2026_10_19_000006) do
  create_table "agents", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_agents_on_email", unique: true
  end

  create_table "customers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "status", default: "inquiry", null: false, comment: "対応ステータス(inquiry: 問い合わせ / viewing_scheduled: 内見予定 / considering: 検討中 / contracted: 成約 / lost: 失注)"
    t.string "name", null: false
    t.string "name_kana", null: false
    t.string "email"
    t.string "phone"
    t.integer "budget_max", comment: "予算上限(万円)"
    t.string "desired_area", comment: "希望エリア"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_customers_on_agent_id"
    t.index ["name_kana"], name: "index_customers_on_name_kana"
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "properties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "prefecture", null: false, comment: "都道府県"
    t.string "city", null: false, comment: "市区町村(政令指定都市は区まで)"
    t.string "address_line", null: false, comment: "町名・番地以降"
    t.integer "price", null: false, comment: "価格(万円)"
    t.string "layout", comment: "間取り(例: 3LDK)"
    t.decimal "floor_area", precision: 7, scale: 2, comment: "専有面積(㎡)"
    t.integer "built_year", comment: "築年(西暦)"
    t.string "nearest_station"
    t.integer "walk_minutes", comment: "駅徒歩(分)"
    t.string "status", default: "available", null: false, comment: "掲載状況(available: 掲載中 / closed: 掲載終了)"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prefecture", "city"], name: "index_properties_on_prefecture_and_city"
    t.index ["status", "price"], name: "index_properties_on_status_and_price"
  end

  create_table "viewings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "property_id", null: false
    t.bigint "agent_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "status", default: "scheduled", null: false, comment: "scheduled: 予定 / completed: 実施済み / canceled: キャンセル"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "status", "starts_at"], name: "index_viewings_on_agent_id_and_status_and_starts_at"
    t.index ["agent_id"], name: "index_viewings_on_agent_id"
    t.index ["customer_id"], name: "index_viewings_on_customer_id"
    t.index ["property_id"], name: "index_viewings_on_property_id"
    t.index ["starts_at"], name: "index_viewings_on_starts_at"
  end

  add_foreign_key "customers", "agents"
  add_foreign_key "viewings", "agents"
  add_foreign_key "viewings", "customers"
  add_foreign_key "viewings", "properties"
end
