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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_000000) do
  create_table "alembic_flow_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "definition_version_id", null: false
    t.integer "flow_id", null: false
    t.string "label"
    t.integer "owner_id"
    t.string "owner_type"
    t.json "recorded"
    t.string "status"
    t.integer "summary_version_id"
    t.datetime "updated_at", null: false
    t.index ["definition_version_id"], name: "index_alembic_flow_runs_on_definition_version_id"
    t.index ["flow_id"], name: "index_alembic_flow_runs_on_flow_id"
    t.index ["owner_type", "owner_id"], name: "index_alembic_responses_on_owner"
    t.index ["summary_version_id"], name: "index_alembic_flow_runs_on_summary_version_id"
  end

  create_table "alembic_flow_summaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "flow_id", null: false
    t.integer "number", null: false
    t.json "summary"
    t.index ["flow_id", "number"], name: "index_alembic_summary_versions_on_diagnostic_and_number", unique: true
    t.index ["flow_id"], name: "index_alembic_flow_summaries_on_flow_id"
  end

  create_table "alembic_flow_versions", force: :cascade do |t|
    t.json "changes_captured"
    t.datetime "created_at", null: false
    t.json "definition"
    t.integer "flow_id", null: false
    t.integer "number", null: false
    t.string "status", default: "draft", null: false
    t.index ["flow_id", "number"], name: "index_alembic_definition_versions_on_diagnostic_and_number", unique: true
    t.index ["flow_id"], name: "index_alembic_definition_versions_on_one_live_per_diagnostic", unique: true, where: "status = 'live'"
    t.index ["flow_id"], name: "index_alembic_flow_versions_on_flow_id"
  end

  create_table "alembic_flows", force: :cascade do |t|
    t.json "changes_since_version"
    t.datetime "created_at", null: false
    t.integer "definition_cursor"
    t.json "document"
    t.string "kind"
    t.string "persists", default: "unsaved", null: false
    t.string "slug"
    t.string "start_label"
    t.string "status", default: "active", null: false
    t.text "summary"
    t.integer "summary_cursor"
    t.string "title"
    t.json "undo_history"
    t.json "undone_changes"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_alembic_flows_on_slug", unique: true
  end

  add_foreign_key "alembic_flow_runs", "alembic_flow_summaries", column: "summary_version_id"
  add_foreign_key "alembic_flow_runs", "alembic_flow_versions", column: "definition_version_id"
  add_foreign_key "alembic_flow_runs", "alembic_flows", column: "flow_id"
  add_foreign_key "alembic_flow_summaries", "alembic_flows", column: "flow_id"
  add_foreign_key "alembic_flow_versions", "alembic_flows", column: "flow_id"
end
