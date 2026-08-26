module Alembic
  module Flow
    FIELD_TYPES = %i[string integer float boolean select multi_select previous_step from_step list].freeze

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
