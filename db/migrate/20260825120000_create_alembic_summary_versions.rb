class CreateAlembicSummaryVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_summary_versions do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.integer :number, null: false
      t.json :summary

      t.datetime :created_at, null: false
    end

    add_index :alembic_summary_versions, [ :diagnostic_id, :number ], unique: true,
      name: "index_alembic_summary_versions_on_diagnostic_and_number"
  end
end
