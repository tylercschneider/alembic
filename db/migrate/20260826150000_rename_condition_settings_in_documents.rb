class RenameConditionSettingsInDocuments < ActiveRecord::Migration[8.1]
  RENAMED = { "answer" => "step", "equals" => "answer" }.freeze

  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      renamed = rename(diagnostic.document)
      next if renamed.nil? || renamed == diagnostic.document

      diagnostic.update!(document: renamed)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "a condition's earlier settings cannot be told apart once renamed"
  end

  private

  def rename(document)
    return if document.blank?

    document.merge("nodes" => Array(document["nodes"]).map { |node| rename_node(node) })
  end

  def rename_node(node)
    return node unless node["type"] == "condition"

    node.except("in").to_h { |key, value| [ RENAMED.fetch(key, key), value ] }
  end
end
