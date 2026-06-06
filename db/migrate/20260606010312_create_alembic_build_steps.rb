class CreateAlembicBuildSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_build_steps do |t|
      t.references :node, null: false, foreign_key: { to_table: :alembic_nodes }
      t.integer :position
      t.string :title
      t.text :code

      t.timestamps
    end
  end
end
