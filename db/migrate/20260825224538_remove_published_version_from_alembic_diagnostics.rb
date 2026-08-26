class RemovePublishedVersionFromAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    remove_reference :alembic_diagnostics, :published_version, foreign_key: { to_table: :alembic_definition_versions }
  end
end
