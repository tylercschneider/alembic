module Alembic
  module Flow
    module Name
      def self.of(node, registry = Flow.registry)
        return "" unless node

        (naming_field(node, registry)&.then { |field| node.config[field.to_s].presence }) || node.id
      end

      def self.naming_field(node, registry)
        registry.fetch(node.type).naming_field if registry.registered?(node.type)
      end
    end
  end
end
