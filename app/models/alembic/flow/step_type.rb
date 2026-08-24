module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :label, :fields, :ports

      def initialize(id:, label:, fields:, ports:)
        @id = id
        @label = label
        @fields = fields
        @ports = ports
      end

      def single_output?
        ports.empty?
      end

      class Declaration
        def initialize(id)
          @id = id
          @label = id.to_s
          @fields = {}
          @ports = []
        end

        def label(value)
          @label = value
        end

        def outputs(*names)
          @ports = names
        end

        def field(name, type)
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @fields[name] = type
        end

        def to_step_type
          StepType.new(id: @id, label: @label, fields: @fields, ports: @ports)
        end
      end
    end
  end
end
