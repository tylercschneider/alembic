class RenameSummaryVersionsToFlowSummaries < ActiveRecord::Migration[8.1]
  def change
    rename_table :alembic_summary_versions, :alembic_flow_summaries
  end
end
