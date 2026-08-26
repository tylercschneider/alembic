module Alembic
  module Flow
    module References
      MENTION = /\{\{\s*(\w+)\s*\}\}/

      def self.of(config)
        mentioned(config.to_h.values).uniq
      end

      def self.mentioned(value)
        case value
        when Hash then mentioned(value.values)
        when Array then value.flat_map { |entry| mentioned(entry) }
        when String then value.scan(MENTION).flatten
        else []
        end
      end
      private_class_method :mentioned
    end
  end
end
