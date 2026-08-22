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

ActiveRecord::Schema[8.1].define(version: 2026_08_22_120100) do
  create_table "alembic_bands", force: :cascade do |t|
    t.integer "ceiling"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "diagnostic_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_bands_on_diagnostic_id"
  end

  create_table "alembic_build_steps", force: :cascade do |t|
    t.text "code"
    t.datetime "created_at", null: false
    t.integer "node_id", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["node_id"], name: "index_alembic_build_steps_on_node_id"
  end

  create_table "alembic_condition_options", force: :cascade do |t|
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.integer "option_id", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_alembic_condition_options_on_condition_id"
    t.index ["option_id"], name: "index_alembic_condition_options_on_option_id"
  end

  create_table "alembic_conditions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "subject_id", null: false
    t.string "subject_type", null: false
    t.integer "tested_question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_type", "subject_id"], name: "index_alembic_conditions_on_subject"
    t.index ["tested_question_id"], name: "index_alembic_conditions_on_tested_question_id"
  end

  create_table "alembic_definition_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "definition"
    t.integer "diagnostic_id", null: false
    t.integer "number", null: false
    t.index ["diagnostic_id", "number"], name: "index_alembic_definition_versions_on_diagnostic_and_number", unique: true
    t.index ["diagnostic_id"], name: "index_alembic_definition_versions_on_diagnostic_id"
  end

  create_table "alembic_diagnostics", force: :cascade do |t|
    t.text "blurb"
    t.datetime "created_at", null: false
    t.json "definition"
    t.string "headline"
    t.string "kicker"
    t.string "kind"
    t.string "resolver_key"
    t.string "slug"
    t.string "start_label"
    t.string "status"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_alembic_diagnostics_on_slug", unique: true
  end

  create_table "alembic_domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.text "gap_cost"
    t.text "gap_meaning"
    t.string "key"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_domains_on_diagnostic_id"
  end

  create_table "alembic_nodes", force: :cascade do |t|
    t.text "avoid"
    t.text "avoid_pain"
    t.text "captures"
    t.text "complexity"
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.string "key"
    t.string "kind"
    t.text "maintenance"
    t.string "name"
    t.text "pains"
    t.integer "position"
    t.text "setup"
    t.text "tagline"
    t.datetime "updated_at", null: false
    t.text "why"
    t.index ["diagnostic_id"], name: "index_alembic_nodes_on_diagnostic_id"
  end

  create_table "alembic_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "hint"
    t.string "label"
    t.integer "position"
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.integer "weight"
    t.index ["question_id"], name: "index_alembic_options_on_question_id"
  end

  create_table "alembic_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.integer "domain_id"
    t.string "key"
    t.integer "position"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_questions_on_diagnostic_id"
    t.index ["domain_id"], name: "index_alembic_questions_on_domain_id"
  end

  create_table "alembic_results", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.string "key"
    t.integer "position"
    t.string "slot"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_results_on_diagnostic_id"
  end

  create_table "alembic_rule_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "result_id", null: false
    t.integer "rule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["result_id"], name: "index_alembic_rule_results_on_result_id"
    t.index ["rule_id"], name: "index_alembic_rule_results_on_rule_id"
  end

  create_table "alembic_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_rules_on_diagnostic_id"
  end

  create_table "alembic_warnings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "diagnostic_id", null: false
    t.string "key"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_alembic_warnings_on_diagnostic_id"
  end

  add_foreign_key "alembic_bands", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_build_steps", "alembic_nodes", column: "node_id"
  add_foreign_key "alembic_condition_options", "alembic_conditions", column: "condition_id"
  add_foreign_key "alembic_condition_options", "alembic_options", column: "option_id"
  add_foreign_key "alembic_conditions", "alembic_questions", column: "tested_question_id"
  add_foreign_key "alembic_definition_versions", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_domains", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_nodes", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_options", "alembic_questions", column: "question_id"
  add_foreign_key "alembic_questions", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_questions", "alembic_domains", column: "domain_id"
  add_foreign_key "alembic_results", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_rule_results", "alembic_results", column: "result_id"
  add_foreign_key "alembic_rule_results", "alembic_rules", column: "rule_id"
  add_foreign_key "alembic_rules", "alembic_diagnostics", column: "diagnostic_id"
  add_foreign_key "alembic_warnings", "alembic_diagnostics", column: "diagnostic_id"
end
