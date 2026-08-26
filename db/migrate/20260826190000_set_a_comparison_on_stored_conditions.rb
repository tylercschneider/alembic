class SetAComparisonOnStoredConditions < ActiveRecord::Migration[8.1]
  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      compared = compare(diagnostic.document)
      next if compared.nil? || compared == diagnostic.document

      diagnostic.update!(document: compared)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "a condition cannot be told from one that never carried a comparison"
  end

  private

  def compare(document)
    return if document.blank?

    document.merge("nodes" => Array(document["nodes"]).map { |node| compare_node(node) })
  end

  def compare_node(node)
    return node unless node["type"] == "condition" && node["comparison"].blank?

    node.merge("comparison" => "is")
  end
end
