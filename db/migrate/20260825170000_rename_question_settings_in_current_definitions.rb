class RenameQuestionSettingsInCurrentDefinitions < ActiveRecord::Migration[8.1]
  RENAMED = { "text" => "question", "options" => "answers", "tag" => "category" }.freeze

  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      renamed = rename(diagnostic.definition)
      next if renamed.nil? || renamed == diagnostic.definition

      diagnostic.record_definition(renamed)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "definition versions are append-only; step back the diagnostic's cursor to undo this"
  end

  private

  def rename(definition)
    return if definition.blank?

    definition.merge("nodes" => Array(definition["nodes"]).map { |node| rename_node(node) })
  end

  def rename_node(node)
    return node unless node["type"] == "question"

    node.to_h { |key, value| [ RENAMED.fetch(key, key), value ] }
  end
end
