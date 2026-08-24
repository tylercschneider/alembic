module Alembic
  module Flow
    class Validator
      def initialize(document)
        @document = document
      end

      def violations
        missing_edge_targets
      end

      private

      def missing_edge_targets
        @document.edges.reject { |edge| known?(edge.to) }
          .map { |edge| Violation.new(node: edge.from, problem: :missing_edge_target, detail: edge.to) }
      end

      def known?(id)
        @document.node(id).present?
      end
    end
  end
end
