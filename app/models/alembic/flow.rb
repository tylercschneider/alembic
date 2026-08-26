module Alembic
  module Flow
    FIELD_TYPES = %i[string integer float boolean select multi_select previous_step from_step list].freeze

    OUTPUT_TYPES = %i[string integer float boolean].freeze
    OPTIONAL_CHECKS = %i[unrouted_value unfollowed_path].freeze

    class UnknownFieldType < ArgumentError; end
    class UnknownOutputType < ArgumentError; end
    class UnknownStepType < KeyError; end
    class UnknownCheck < ArgumentError; end
    class InvalidEdit < StandardError; end

    class << self
      def step(id, &declaration)
        registry.register(StepType.define(id, &declaration))
      end

      def registry
        @registry ||= Registry.new
      end

      def check(name)
        raise UnknownCheck, "#{name} is not one of #{OPTIONAL_CHECKS.join(', ')}" unless OPTIONAL_CHECKS.include?(name)

        checks << name unless checks.include?(name)
      end

      def checks
        @checks ||= []
      end
    end
  end
end
