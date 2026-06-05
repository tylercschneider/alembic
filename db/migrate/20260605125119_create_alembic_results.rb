class CreateAlembicResults < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_results do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.string :slot
      t.string :key
      t.string :title
      t.text :body
      t.integer :position

      t.timestamps
    end
  end
end
