module Alembic
  module Flow
    class Digest
      def initialize(document, registry: Flow.registry)
        @document = document
        @registry = registry
      end

      def entry
        @document.node(@document.entry)
      end

      def step(id)
        @document.node(id)
      end

      def steps
        @document.nodes
      end

      def preceding(id)
        return [] unless @document.reachable.include?(id)

        @document.nodes.map(&:id).uniq
          .reject { |other| other == id || @document.reachable(without: other).include?(id) }
      end

      def values_out_of(id)
        named = step(id)
        return [] unless named

        step_type(named)&.outputs.to_a.flat_map { |output| output.values_for(named) }
      end

      def requirements(id)
        node = step(id)
        step_type(node)&.requirements_for(node).to_a
      end

      def next_step(state)
        walk(state).last
      end

      def state_on_path(state)
        state.slice(*walk(state).first)
      end

      private

      def walk(state)
        recorded = []
        visited = []
        cursor = entry

        while cursor && !visited.include?(cursor.id)
          return [ recorded, cursor ] if pending?(cursor, state)

          recorded << cursor.id if state.key?(cursor.id)
          visited << cursor.id
          cursor = successor(cursor, state)
        end

        [ recorded, nil ]
      end

      def pending?(node, state)
        step_type(node)&.awaits_input? && !state.key?(node.id)
      end

      def successor(node, state)
        leaving = @document.edges_from(node.id)
        port = step_type(node)&.route(node, state)
        taken = port.nil? ? leaving.first : leaving.find { |edge| edge.on.to_s == port.to_s }

        taken && @document.node(taken.to)
      end

      def step_type(node)
        @registry.fetch(node.type) if node && @registry.registered?(node.type)
      end
    end
  end
end
