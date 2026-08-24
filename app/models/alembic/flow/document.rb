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

      def entry
        @document["entry"]
      end

      def node(id)
        nodes.find { |node| node.id == id }
      end

      def edges_from(id)
        edges.select { |edge| edge.from == id }
      end

      def to_h
        @document
      end

      def insert(node, on:)
        source, target = on
        replaced = raw_edges.find { |edge| edge["from"] == source && edge["to"] == target }
        bridged = [ { "from" => source, "to" => node["id"], "on" => replaced&.fetch("on", nil) }.compact,
                    { "from" => node["id"], "to" => target } ]

        with(nodes: raw_nodes + [ node ], edges: (raw_edges - [ replaced ]) + bridged)
      end

      private

      def raw_nodes
        Array(@document["nodes"])
      end

      def raw_edges
        Array(@document["edges"])
      end

      def with(nodes:, edges:)
        Document.new(@document.merge("nodes" => nodes, "edges" => edges))
      end
    end
  end
end
