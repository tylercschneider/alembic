class RemovePublishedVersionFromAlembicDiagnostics < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE alembic_definition_versions
         SET status = 'live'
       WHERE id IN (SELECT published_version_id FROM alembic_diagnostics WHERE published_version_id IS NOT NULL)
    SQL

    remove_reference :alembic_diagnostics, :published_version, foreign_key: { to_table: :alembic_definition_versions }
  end

  def down
    add_reference :alembic_diagnostics, :published_version, foreign_key: { to_table: :alembic_definition_versions }

    execute <<~SQL
      UPDATE alembic_diagnostics
         SET published_version_id = (SELECT id FROM alembic_definition_versions
                                      WHERE diagnostic_id = alembic_diagnostics.id AND status = 'live')
    SQL
  end
end
