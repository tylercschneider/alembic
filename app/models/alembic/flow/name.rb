module Alembic
  module Flow
    module Name
      def self.of(node, registry = Flow.registry)
        return "" unless node

        naming_fields(node, registry).filter_map { |field| node.config[field.to_s].presence }.first || node.id
      end

      def self.naming_fields(node, registry)
        registry.registered?(node.type) ? registry.fetch(node.type).naming_fields : []
      end
    end
  end
end
