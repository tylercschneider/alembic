class MoveSummaryDefinitionsIntoVersions < ActiveRecord::Migration[8.1]
  class Diagnostic < ActiveRecord::Base
    self.table_name = "alembic_diagnostics"
  end

  class SummaryVersion < ActiveRecord::Base
    self.table_name = "alembic_summary_versions"
  end

  def up
    Diagnostic.where.not(summary_definition: nil).find_each do |diagnostic|
      version = SummaryVersion.create!(diagnostic_id: diagnostic.id, number: 1,
        summary: diagnostic.summary_definition, created_at: Time.current)

      diagnostic.update_columns(summary_cursor: version.number)
    end
  end

  def down
    SummaryVersion.where(number: 1).find_each do |version|
      Diagnostic.where(id: version.diagnostic_id)
        .update_all(summary_definition: version.summary, summary_cursor: nil)
      version.delete
    end
  end
end
