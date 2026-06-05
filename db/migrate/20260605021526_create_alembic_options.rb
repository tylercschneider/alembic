class CreateAlembicOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_options do |t|
      t.references :question, null: false, foreign_key: { to_table: :alembic_questions }
      t.integer :position
      t.string :value
      t.string :label
      t.text :hint
      t.integer :weight

      t.timestamps
    end
  end
end
