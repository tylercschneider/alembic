class CreateAlembicDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_domains do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.string :key
      t.string :name
      t.text :gap_meaning
      t.text :gap_cost
      t.integer :position

      t.timestamps
    end
  end
end
