class AddUndoHistoryToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :undo_history, :json
  end
end
