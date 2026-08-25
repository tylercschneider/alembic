class AddSummaryDefinitionToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :summary_definition, :json
  end
end
