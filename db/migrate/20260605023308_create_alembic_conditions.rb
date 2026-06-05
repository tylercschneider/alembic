class CreateAlembicConditions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_conditions do |t|
      t.references :question, null: false, foreign_key: { to_table: :alembic_questions }
      t.string :depends_on
      t.json :values

      t.timestamps
    end
  end
end
