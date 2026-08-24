class CreateAlembicTransitions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_transitions do |t|
      t.references :from_question, null: false, foreign_key: { to_table: :alembic_questions }
      t.references :to_question, null: false, foreign_key: { to_table: :alembic_questions }

      t.timestamps
    end
  end
end
