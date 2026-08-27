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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_234500) do
  create_table "alembic_definition_versions", force: :cascade do |t|
    t.json "changes_captured"
    t.datetime "created_at", null: false
    t.json "definition"
    t.integer "diagnostic_id", null: false
    t.integer "number", null: false
    t.string "status", default: "draft", null: false
    t.index ["diagnostic_id", "number"], name: "index_alembic_definition_versions_on_diagnostic_and_number", unique: true
    t.index ["diagnostic_id"], name: "index_alembic_definition_versions_on_diagnostic_id"
    t.index ["diagnostic_id"], name: "index_alembic_definition_versions_on_one_live_per_diagnostic", unique: true, where: "status = 'live'"
  end

  create_table "alembic_diagnostics", force: :cascade do |t|
    t.json "changes_since_version"
    t.datetime "created_at", null: false
    t.integer "definition_cursor"
    t.json "document"
    t.string "kind"
    t.string "slug"
    t.string "start_label"
    t.string "status", default: "active", null: false
    t.text "summary"
    t.integer "summary_cursor"
    t.string "title"
    t.json "undo_history"
    t.json "undone_changes"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_alembic_diagnostics_on_slug", unique: true
  end

  create_table "alembic_flow_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "definition_version_id", null: false
    t.integer "diagnostic_id", null: false
    t.string "label"
    t.integer "owner_id"
    t.string "owner_type"
    t.json "recorded"
    t.string "status"
    t.integer "summary_version_id"
    t.datetime "updated_at", null: false
    t.index ["definition_version_id"], name: "index_alembic_flow_runs_on_definition_version_id"
    t.index ["diagnostic_id"], name: "index_alembic_flow_runs_on_diagnostic_id"
    t.index ["owner_type", "owner_id"], name: "index_alembic_responses_on_owner"
    t.index ["summary_version_id"], name: "index_alembic_flow_runs_on_summary_version_id"
  end

  create_table "alembic_summary_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.integer "number", null: false
    t.json "summary"
    t.index ["diagnostic_id", "number"], name: "index_alembic_summary_versions_on_diagnostic_and_number", unique: true
    t.index ["diagnostic_id"], name: "index_alembic_summary_versions_on_diagnostic_id"
  end

  add_foreign_key "alembic_definition_versions", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_flow_runs", "alembic_definition_versions", column: "definition_version_id"
  add_foreign_key "alembic_flow_runs", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_flow_runs", "alembic_summary_versions", column: "summary_version_id"
  add_foreign_key "alembic_summary_versions", "alembic_diagnostics", column: "diagnostic_id"
end
