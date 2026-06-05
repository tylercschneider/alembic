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

ActiveRecord::Schema[8.1].define(version: 2026_06_05_015051) do
  create_table "alembic_diagnostics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind"
    t.string "slug"
    t.string "status"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_alembic_diagnostics_on_slug", unique: true
  end

  create_table "alembic_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.string "key"
    t.integer "position"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_questions_on_diagnostic_id"
  end

  add_foreign_key "alembic_questions", "alembic_diagnostics", column: "diagnostic_id"
end
