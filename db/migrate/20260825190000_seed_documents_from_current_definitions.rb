class SeedDocumentsFromCurrentDefinitions < ActiveRecord::Migration[8.1]
  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      next if diagnostic.definition.blank?

      diagnostic.update_columns(document: diagnostic.definition)
    end
  end

  def down
    Alembic::Diagnostic.update_all(document: nil)
  end
end
