module Alembic
  module Summary
    class Registry
      def initialize
        @output_types = {}
      end

      def register(output_type)
        @output_types[output_type.id.to_sym] = output_type
      end

      def fetch(id)
        @output_types.fetch(id.to_sym) { raise UnknownOutputType, "no output type registered as #{id}" }
      end

      def registered?(id)
        id.present? && @output_types.key?(id.to_sym)
      end

      def output_types
        @output_types.values
      end
    end
  end
end
