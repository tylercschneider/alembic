class AddPersistsToAlembicFlows < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_flows, :persists, :string, default: "unsaved", null: false
  end
end
