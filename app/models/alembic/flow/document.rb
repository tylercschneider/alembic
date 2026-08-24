module Alembic
  module Flow
    class Document
      def initialize(document)
        @document = document
      end

      def nodes
        Array(@document["nodes"]).map { |node| Node.new(id: node["id"], type: node["type"], config: node.except("id", "type")) }
      end
    end
  end
end
