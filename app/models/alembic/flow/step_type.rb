module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :label

      def initialize(id:, label:)
        @id = id
        @label = label
      end

      class Declaration
        def initialize(id)
          @id = id
          @label = id.to_s
        end

        def label(value)
          @label = value
        end

        def to_step_type
          StepType.new(id: @id, label: @label)
        end
      end
    end
  end
end
