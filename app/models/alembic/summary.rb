module Alembic
  module Summary
    class UnknownOutputType < KeyError; end

    class << self
      def output(id, &declaration)
        registry.register(OutputType.define(id, &declaration))
      end

      def registry
        @registry ||= Registry.new
      end
    end
  end
end
