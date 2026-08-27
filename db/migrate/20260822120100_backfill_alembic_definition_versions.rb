class BackfillAlembicDefinitionVersions < ActiveRecord::Migration[8.1]
  def up
    Alembic::Flow::Flow.find_each do |diagnostic|
      next if diagnostic.definition.blank? || diagnostic.definition_versions.exists?

      diagnostic.definition_versions.create!(number: 1, definition: diagnostic.definition)
    end
  end
end
