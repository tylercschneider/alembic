module Alembic
  module Flow
    class Validator
      def initialize(document)
        @document = document
      end

      def violations
        missing_edge_targets + missing_edge_sources + duplicate_ids + missing_entry + unreachable
      end

      private

      def missing_edge_targets
        @document.edges.reject { |edge| known?(edge.to) }
          .map { |edge| Violation.new(node: edge.from, problem: :missing_edge_target, detail: edge.to) }
      end

      def missing_edge_sources
        @document.edges.reject { |edge| known?(edge.from) }
          .map { |edge| Violation.new(node: edge.to, problem: :missing_edge_source, detail: edge.from) }
      end

      def duplicate_ids
        @document.nodes.map(&:id).tally.select { |_id, count| count > 1 }
          .map { |id, _count| Violation.new(node: id, problem: :duplicate_id) }
      end

      def missing_entry
        return [] if known?(@document.entry)

        [ Violation.new(node: @document.entry, problem: :missing_entry) ]
      end

      def unreachable
        return [] unless known?(@document.entry)

        (@document.nodes.map(&:id).uniq - reachable).map { |id| Violation.new(node: id, problem: :unreachable) }
      end

      def reachable
        found = []
        frontier = [ @document.entry ]

        while (id = frontier.shift)
          next if found.include?(id)

          found << id
          frontier.concat(@document.edges_from(id).map(&:to))
        end

        found
      end

      def known?(id)
        @document.node(id).present?
      end
    end
  end
end
