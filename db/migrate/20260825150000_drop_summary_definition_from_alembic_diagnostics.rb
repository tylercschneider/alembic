class DropSummaryDefinitionFromAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    remove_column :alembic_diagnostics, :summary_definition, :json
  end
end
