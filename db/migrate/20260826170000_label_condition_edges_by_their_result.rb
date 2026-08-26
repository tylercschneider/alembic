class LabelConditionEdgesByTheirResult < ActiveRecord::Migration[8.1]
  RELABELLED = { "yes" => true, "no" => false }.freeze

  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      relabelled = relabel(diagnostic.document)
      next if relabelled.nil? || relabelled == diagnostic.document

      diagnostic.update!(document: relabelled)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "an edge's earlier port name cannot be told from the result it now carries"
  end

  private

  def relabel(document)
    return if document.blank?

    deciding = Array(document["nodes"]).select { |node| node["type"] == "condition" }.map { |node| node["id"] }
    document.merge("edges" => Array(document["edges"]).map { |edge| relabel_edge(edge, deciding) })
  end

  def relabel_edge(edge, deciding)
    return edge unless deciding.include?(edge["from"]) && RELABELLED.key?(edge["on"])

    edge.merge("on" => RELABELLED.fetch(edge["on"]))
  end
end
