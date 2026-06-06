class CreateAlembicWarnings < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_warnings do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.string :key
      t.text :text

      t.timestamps
    end
  end
end
