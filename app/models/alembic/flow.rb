module Alembic
  module Flow
    FIELD_TYPES = %i[text integer float boolean select list records].freeze

    class UnknownFieldType < ArgumentError; end
    class UnknownStepType < KeyError; end
    class InvalidEdit < StandardError; end

    class << self
      def step(id, &declaration)
        registry.register(StepType.define(id, &declaration))
      end

      def registry
        @registry ||= Registry.new
      end
    end
  end
end
