class CreateAlembicQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_questions do |t|
      t.references :diagnostic, null: false, foreign_key: { to_table: :alembic_diagnostics }
      t.integer :position
      t.string :key
      t.text :text

      t.timestamps
    end
  end
end
