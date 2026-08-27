class RenameDiagnosticsToFlows < ActiveRecord::Migration[8.1]
  def change
    rename_table :alembic_diagnostics, :alembic_flows
    rename_column :alembic_flow_versions, :diagnostic_id, :flow_id
    rename_column :alembic_flow_summaries, :diagnostic_id, :flow_id
    rename_column :alembic_flow_runs, :diagnostic_id, :flow_id
  end
end
