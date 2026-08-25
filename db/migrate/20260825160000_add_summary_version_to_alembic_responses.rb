class AddSummaryVersionToAlembicResponses < ActiveRecord::Migration[8.1]
  def change
    add_reference :alembic_responses, :summary_version, null: true,
      foreign_key: { to_table: :alembic_summary_versions }
  end
end
