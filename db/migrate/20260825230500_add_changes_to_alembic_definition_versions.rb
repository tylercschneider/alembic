class AddChangesToAlembicDefinitionVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_definition_versions, :changes_captured, :json
  end
end
