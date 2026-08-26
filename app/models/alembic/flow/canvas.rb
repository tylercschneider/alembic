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
          { "id" => node.id, "type" => node.type, "label" => label_for(node),
            "config" => node.config, "ports" => ports_for(node),
            "choices" => choices_for(node), **placed[node.id] }
        end
      end

      def edges
        placed = Layout.new(@document).positions

        @document.edges.each_with_index.map do |edge, index|
          { "id" => "#{edge.from}-#{edge.to}-#{index}", "source" => edge.from, "target" => edge.to, "label" => edge.on }
            .merge(routing(edge, placed))
        end
      end

      def routing(edge, placed)
        from = placed[edge.from]
        to = placed[edge.to]
        return { "leaves" => "bottom", "enters" => "top", "route" => "straight" } unless from && to

        return alongside_routing(from, to) unless to["row"] > from["row"]
        return branch_routing(from, to) if branching?(edge, from, to)

        { "leaves" => "bottom", "enters" => "top",
          "route" => to["column"] == from["column"] ? "straight" : "lane" }
      end

      def branch_routing(from, to)
        { "leaves" => to["column"] < from["column"] ? "left" : "right", "enters" => "top", "route" => "turn" }
      end

      def alongside_routing(from, to)
        leftward = to["column"] < from["column"]

        { "leaves" => leftward ? "left" : "right", "enters" => leftward ? "right" : "left",
          "route" => to["row"] == from["row"] ? "straight" : "detour" }
      end

      def branching?(edge, from, to)
        to["column"] != from["column"] && @document.edges_from(edge.from).size > 1
      end

      def palette
        @registry.step_types.map do |step_type|
          { "type" => step_type.id.to_s, "label" => step_type.step_name,
            "fields" => step_type.fields.transform_keys(&:to_s).transform_values(&:to_s),
            "labels" => step_type.labels.transform_keys(&:to_s),
            "choices" => step_type.choices.transform_keys(&:to_s),
            "records" => holdings_of(step_type),
            "record_labels" => step_type.record_labels.to_h { |name, held| [ name.to_s, held.transform_keys(&:to_s) ] },
            "awaits_input" => step_type.awaits_input? }
        end
      end

      def holdings_of(step_type)
        step_type.record_fields.to_h do |name, holds|
          [ name.to_s, holds.transform_keys(&:to_s).transform_values(&:to_s) ]
        end
      end

      def violations
        Validator.new(@document, registry: @registry).violations.map do |violation|
          { "node" => violation.node, "problem" => violation.problem.to_s, "detail" => violation.detail }
        end
      end

      def label_for(node)
        Name.of(node, @registry)
      end

      def choices_for(node)
        naming_steps(node).index_with { earlier_than(node) }.merge(drawn_by(node)).merge(named_outputs_by(node))
      end

      def named_outputs_by(node)
        step_type_for(node)&.outputs_of.to_h.to_h do |name, source|
          [ name.to_s, digest.outputs_of(node.config[source.to_s]) ]
        end
      end

      def drawn_by(node)
        step_type_for(node)&.drawn_from.to_h.to_h do |name, source|
          [ name.to_s, digest.values_of(step_named_by(node, source), node.config[source.to_s]) ]
        end
      end

      def step_named_by(node, source)
        node.config[step_type_for(node).outputs_of[source].to_s]
      end

      def digest
        Digest.new(@document, registry: @registry)
      end

      def naming_steps(node)
        step_type_for(node)&.fields.to_h.select { |_name, type| type == :previous_step }.keys.map(&:to_s)
      end

      def earlier_than(node)
        digest.preceding(node.id).map do |id|
          { "value" => id, "label" => label_for(@document.node(id)) }
        end
      end

      def ports_for(node)
        digest.routing_values(node.id)
      end

      def step_type_for(node)
        @registry.fetch(node.type) if @registry.registered?(node.type)
      end
    end
  end
end
