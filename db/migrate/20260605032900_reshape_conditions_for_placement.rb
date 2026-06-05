class ReshapeConditionsForPlacement < ActiveRecord::Migration[8.1]
  def change
    add_reference :alembic_conditions, :subject, polymorphic: true, null: false
    add_reference :alembic_conditions, :tested_question, null: false,
      foreign_key: { to_table: :alembic_questions }

    remove_reference :alembic_conditions, :question, foreign_key: { to_table: :alembic_questions }
    remove_column :alembic_conditions, :depends_on, :string
    remove_column :alembic_conditions, :values, :json
  end
end
