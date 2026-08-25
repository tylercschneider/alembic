class AddDocumentToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :document, :json
    add_column :alembic_diagnostics, :changes_since_version, :json
  end
end
