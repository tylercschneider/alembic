class EndStoredFlowsAtATerminal < ActiveRecord::Migration[8.1]
  def up
    Alembic::Diagnostic.find_each do |diagnostic|
      ended = end_flow(diagnostic.document)
      next if ended.nil? || ended == diagnostic.document

      diagnostic.update!(document: ended)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "a terminal added here cannot be told from one an author placed"
  end

  private

  def end_flow(document)
    return if document.blank?

    stopping = dead_ends(document)
    return document if stopping.empty?

    document.merge("nodes" => Array(document["nodes"]) + [ { "id" => terminal_id(document), "type" => "terminal" } ],
                   "edges" => Array(document["edges"]) + stopping.map { |id| { "from" => id, "to" => terminal_id(document) } })
  end

  def dead_ends(document)
    leaving = Array(document["edges"]).map { |edge| edge["from"] }

    Array(document["nodes"]).reject { |node| node["type"] == "terminal" || leaving.include?(node["id"]) }
      .map { |node| node["id"] }
  end

  def terminal_id(document)
    taken = Array(document["nodes"]).map { |node| node["id"] }
    candidate = "end"
    suffix = 2
    candidate = "end_#{suffix += 1}" while taken.include?(candidate)
    candidate
  end
end
