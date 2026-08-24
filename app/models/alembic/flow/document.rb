module Alembic
  module Flow
    class Document
      def initialize(document)
        @document = document
      end

      def nodes
        Array(@document["nodes"]).map { |node| Node.new(id: node["id"], type: node["type"], config: node.except("id", "type")) }
      end

      def edges
        Array(@document["edges"]).map { |edge| Edge.new(from: edge["from"], to: edge["to"], on: edge["on"]) }
      end
    end
  end
end
