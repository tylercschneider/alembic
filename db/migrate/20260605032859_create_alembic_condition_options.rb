class CreateAlembicConditionOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_condition_options do |t|
      t.references :condition, null: false, foreign_key: { to_table: :alembic_conditions }
      t.references :option, null: false, foreign_key: { to_table: :alembic_options }

      t.timestamps
    end
  end
end
