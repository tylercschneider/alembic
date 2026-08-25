module Alembic
  module Summary
    class OutputType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_output_type
      end

      attr_reader :id, :label

      def initialize(id:, label:, computation:)
        @id = id
        @label = label
        @computation = computation
      end

      def compute(config, state, so_far)
        @computation&.call(config, state, so_far)
      end

      class Declaration
        def initialize(id)
          @id = id
          @label = id.to_s
        end

        def label(value)
          @label = value
        end

        def compute(&computation)
          @computation = computation
        end

        def to_output_type
          OutputType.new(id: @id, label: @label, computation: @computation)
        end
      end
    end
  end
end
