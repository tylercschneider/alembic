class CreateAlembicBands < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_bands do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.integer :ceiling
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
