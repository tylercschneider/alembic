class SeedDocumentsFromCurrentDefinitions < ActiveRecord::Migration[8.1]
  def up
    Alembic::Flow::Flow.find_each do |diagnostic|
      next if diagnostic.definition.blank?

      diagnostic.update_columns(document: diagnostic.definition)
    end
  end

  def down
    Alembic::Flow::Flow.update_all(document: nil)
  end
end
