class RenameAlembicResponsesToFlowRuns < ActiveRecord::Migration[8.1]
  def change
    rename_table :alembic_responses, :alembic_flow_runs
  end
end
