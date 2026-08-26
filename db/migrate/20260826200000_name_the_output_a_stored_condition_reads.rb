class NameTheOutputAStoredConditionReads < ActiveRecord::Migration[8.1]
  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      named = name_outputs(diagnostic.document)
      next if named.nil? || named == diagnostic.document

      diagnostic.update!(document: named)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "a condition cannot be told from one that never named the output it reads"
  end

  private

  def name_outputs(document)
    return if document.blank?

    document.merge("nodes" => Array(document["nodes"]).map { |node| name_output(node) })
  end

  def name_output(node)
    return node unless node["type"] == "condition" && node["output"].blank?

    node.merge("output" => "answer")
  end
end
