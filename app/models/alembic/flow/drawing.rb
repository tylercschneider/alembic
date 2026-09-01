module Alembic
  module Flow
    module Drawing
      def self.of(node, registry = Flow.registry)
        named(node, registry).presence || Flow.drawing
      end

      def self.named(node, registry)
        return unless node && registry.registered?(node.type)

        registry.fetch(node.type).drawn_by
      end
    end
  end
end
