module Alembic
  module Flow
    module References
      MENTION = /\{\{\s*(\w+)\s*\}\}/

      def self.of(config)
        config.to_h.values.flat_map { |value| value.to_s.scan(MENTION) }.flatten
      end
    end
  end
end
