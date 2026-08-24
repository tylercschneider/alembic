module Alembic
  module Flow
    FIELD_TYPES = %i[text string number boolean select list].freeze

    class UnknownFieldType < ArgumentError; end
    class UnknownStepType < KeyError; end

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
