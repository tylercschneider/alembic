class AddUndoneChangesToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :undone_changes, :json
  end
end
