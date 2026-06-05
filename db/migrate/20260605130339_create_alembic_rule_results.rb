class CreateAlembicRuleResults < ActiveRecord::Migration[8.1]
  def change
    create_table :alembic_rule_results do |t|
      t.references :rule, null: false, foreign_key: { to_table: :alembic_rules }
      t.references :result, null: false, foreign_key: { to_table: :alembic_results }

      t.timestamps
    end
  end
end
