class CreateAlembicNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_nodes do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.string :kind
      t.string :key
      t.integer :position
      t.string :name
      t.text :tagline
      t.text :complexity
      t.text :setup
      t.text :maintenance
      t.text :captures
      t.text :why
      t.text :pains
      t.text :avoid
      t.text :avoid_pain

      t.timestamps
    end
  end
end
