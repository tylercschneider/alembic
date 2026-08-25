class AddSummaryCursorToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :summary_cursor, :integer
  end
end
