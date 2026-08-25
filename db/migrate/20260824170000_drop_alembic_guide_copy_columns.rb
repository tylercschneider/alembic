class DropAlembicGuideCopyColumns < ActiveRecord::Migration[8.1]
  def up
    remove_column :alembic_diagnostics, :kicker
    remove_column :alembic_diagnostics, :headline
    remove_column :alembic_diagnostics, :blurb
    remove_column :alembic_diagnostics, :resolver_key
  end
end
