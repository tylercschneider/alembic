class AddPublishedVersionToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_reference :alembic_diagnostics, :published_version, null: true,
      foreign_key: { to_table: :alembic_definition_versions }
  end
end
