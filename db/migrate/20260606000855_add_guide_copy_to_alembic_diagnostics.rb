class AddGuideCopyToAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def change
    add_column :alembic_diagnostics, :kicker, :string
    add_column :alembic_diagnostics, :headline, :string
    add_column :alembic_diagnostics, :blurb, :text
    add_column :alembic_diagnostics, :start_label, :string
    add_column :alembic_diagnostics, :resolver_key, :string
  end
end
