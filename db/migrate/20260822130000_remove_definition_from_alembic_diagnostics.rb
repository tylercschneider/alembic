class RemoveDefinitionFromAlembicDiagnostics < ActiveRecord::Migration[8.1]
  class Flow::Flow < ActiveRecord::Base
    self.table_name = "alembic_diagnostics"
  end

  class DefinitionVersion < ActiveRecord::Base
    self.table_name = "alembic_definition_versions"
  end

  def up
    record_definitions_held_only_by_the_column
    remove_column :alembic_diagnostics, :definition
  end

  def down
    add_column :alembic_diagnostics, :definition, :json
  end

  private

  def record_definitions_held_only_by_the_column
    Flow::Flow.where.not(definition: nil).find_each do |diagnostic|
      next if DefinitionVersion.exists?(diagnostic_id: diagnostic.id)

      DefinitionVersion.create!(diagnostic_id: diagnostic.id, number: 1, definition: diagnostic.definition)
    end
  end
end
