class AddDefinitionCursorToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :definition_cursor, :integer
  end
end
