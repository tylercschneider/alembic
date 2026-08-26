module Alembic
  module Flow
    class Validator
      def initialize(document, registry: Flow.registry)
        @document = document
        @registry = registry
      end

      def violations
        structural_violations + unmet_requirements + missing_settings
      end

      def structural_violations
        malformations + unreachable
      end

      def malformations
        missing_edge_targets + missing_edge_sources + duplicate_ids + missing_entry
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

      def unmet_requirements
        @document.nodes.flat_map do |node|
          requirements_for(node).reject { |required| precedes_every_path?(required, node.id) }
            .map { |required| Violation.new(node: node.id, problem: :unmet_requirement, detail: required) }
        end
      end

      def missing_settings
        @document.nodes.flat_map do |node|
          required_of(node).reject { |name| node.config[name.to_s].present? }
            .map { |name| Violation.new(node: node.id, problem: :missing_setting, detail: name.to_s) }
        end
      end

      def required_of(node)
        return [] unless @registry.registered?(node.type)

        @registry.fetch(node.type).required
      end

      def requirements_for(node)
        return [] unless @registry.registered?(node.type)

        @registry.fetch(node.type).requirements_for(node)
      end

      def precedes_every_path?(required, id)
        known?(required) && !@document.reachable(without: required).include?(id)
      end

      def unreachable
        return [] unless known?(@document.entry)

        (@document.nodes.map(&:id).uniq - @document.reachable).map { |id| Violation.new(node: id, problem: :unreachable) }
      end

      def known?(id)
        @document.node(id).present?
      end
    end
  end
end
