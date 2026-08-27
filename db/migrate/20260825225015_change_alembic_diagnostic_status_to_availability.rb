class ChangeAlembicDiagnosticStatusToAvailability < ActiveRecord::Migration[8.1]
  def up
    Alembic::Flow::Definition.update_all(status: "active")
    change_column_default :alembic_diagnostics, :status, "active"
    change_column_null :alembic_diagnostics, :status, false, "active"
  end

  def down
    change_column_null :alembic_diagnostics, :status, true
    change_column_default :alembic_diagnostics, :status, nil
  end
end
