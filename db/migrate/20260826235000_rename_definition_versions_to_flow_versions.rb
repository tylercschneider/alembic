class RenameDefinitionVersionsToFlowVersions < ActiveRecord::Migration[8.1]
  def change
    rename_table :alembic_definition_versions, :alembic_flow_versions
  end
end
