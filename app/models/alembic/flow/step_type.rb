module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :label, :fields, :ports, :naming_field

      def initialize(id:, label:, fields:, ports:, awaits_input:, requirements:, behaviour:, routing:, naming_field: nil)
        @id = id
        @label = label
        @fields = fields
        @ports = ports
        @awaits_input = awaits_input
        @requirements = requirements
        @behaviour = behaviour
        @routing = routing
        @naming_field = naming_field
      end

      def process(node, state)
        @behaviour&.call(node, state)
      end

      def route(node, state)
        @routing&.call(node, state)
      end

      def requirements_for(node)
        Array(@requirements&.call(node))
      end

      def awaits_input?
        @awaits_input
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
          @awaits_input = false
        end

        def requires(&derivation)
          @requirements = derivation
        end

        def process(&behaviour)
          @behaviour = behaviour
        end

        def route(&routing)
          @routing = routing
        end

        def label(value)
          @label = value
        end

        def awaits_input
          @awaits_input = true
        end

        def names_by(field)
          @naming_field = field
        end

        def outputs(*names)
          @ports = names
        end

        def field(name, type)
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @fields[name] = type
        end

        def to_step_type
          StepType.new(id: @id, label: @label, fields: @fields, ports: @ports, awaits_input: @awaits_input, requirements: @requirements, behaviour: @behaviour, routing: @routing, naming_field: @naming_field)
        end
      end
    end
  end
end
