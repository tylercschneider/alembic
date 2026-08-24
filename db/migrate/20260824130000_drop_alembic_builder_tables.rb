class DropAlembicBuilderTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :alembic_condition_options
    drop_table :alembic_conditions
    drop_table :alembic_transitions
    drop_table :alembic_options
    drop_table :alembic_build_steps
    drop_table :alembic_rule_results
    drop_table :alembic_rules
    drop_table :alembic_results
    drop_table :alembic_questions
    drop_table :alembic_nodes
    drop_table :alembic_warnings
    drop_table :alembic_bands
    drop_table :alembic_domains
  end
end
