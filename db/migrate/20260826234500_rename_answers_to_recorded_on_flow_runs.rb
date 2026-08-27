class RenameAnswersToRecordedOnFlowRuns < ActiveRecord::Migration[8.1]
  def change
    rename_column :alembic_flow_runs, :answers, :recorded
  end
end
