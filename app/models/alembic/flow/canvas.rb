module Alembic
  module Flow
    class Canvas
      def initialize(document, registry: Flow.registry)
        @document = document
        @registry = registry
      end

      def to_h
        { "nodes" => nodes, "edges" => edges, "palette" => palette, "violations" => violations }
      end

      private

      def nodes
        placed = Layout.new(@document).positions

        @document.nodes.map do |node|
          { "id" => node.id, "type" => node.type, "position" => placed[node.id],
            "label" => label_for(node), "config" => node.config, "ports" => ports_for(node),
            "sourcePosition" => source_side(node, placed), "targetPosition" => target_side(node, placed) }
        end
      end

      def source_side(node, placed)
        beside = alongside(node, placed, @document.edges_from(node.id).map(&:to))
        return "bottom" unless beside

        beside["x"] > placed[node.id]["x"] ? "right" : "left"
      end

      def target_side(node, placed)
        arriving = @document.edges.select { |edge| edge.to == node.id }.map(&:from)
        beside = alongside(node, placed, arriving)
        return "top" unless beside

        beside["x"] < placed[node.id]["x"] ? "left" : "right"
      end

      def alongside(node, placed, neighbours)
        here = placed[node.id]

        neighbours.filter_map { |id| placed[id] }.find { |there| there["y"] == here["y"] }
      end

      def edges
        @document.edges.each_with_index.map do |edge, index|
          { "id" => "#{edge.from}-#{edge.to}-#{index}", "source" => edge.from, "target" => edge.to, "label" => edge.on }
        end
      end

      def palette
        @registry.step_types.map do |step_type|
          { "type" => step_type.id.to_s, "label" => step_type.label,
            "fields" => step_type.fields.transform_keys(&:to_s).transform_values(&:to_s),
            "ports" => step_type.ports.map(&:to_s), "awaits_input" => step_type.awaits_input? }
        end
      end

      def violations
        Validator.new(@document, registry: @registry).violations.map do |violation|
          { "node" => violation.node, "problem" => violation.problem.to_s, "detail" => violation.detail }
        end
      end

      def label_for(node)
        naming_field = step_type_for(node)&.fields&.keys&.first

        (naming_field && node.config[naming_field.to_s].presence) || node.id
      end

      def ports_for(node)
        step_type_for(node)&.ports.to_a.map(&:to_s)
      end

      def step_type_for(node)
        @registry.fetch(node.type) if @registry.registered?(node.type)
      end
    end
  end
end
