class AddStatusToAlembicDefinitionVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_definition_versions, :status, :string, null: false, default: "draft"

    add_index :alembic_definition_versions, :diagnostic_id, unique: true,
      where: "status = 'live'", name: "index_alembic_definition_versions_on_one_live_per_diagnostic"
  end
end
