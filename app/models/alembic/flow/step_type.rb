module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :label, :fields, :record_fields, :ports, :naming_field

      def initialize(id:, label:, fields:, ports:, awaits_input:, requirements:, behaviour:, routing:, naming_field: nil, record_fields: {})
        @id = id
        @label = label
        @fields = fields
        @ports = ports
        @awaits_input = awaits_input
        @requirements = requirements
        @behaviour = behaviour
        @routing = routing
        @naming_field = naming_field
        @record_fields = record_fields
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
          @record_fields = {}
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

        def setting(name, type:, &entries)
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @record_fields[name] = holdings(entries) if type == :list
          @fields[name] = type
        end

        protected

        attr_reader :fields

        private

        def holdings(entries)
          raise UnknownFieldType, "a list must say what an entry holds" if entries.nil?

          Declaration.new(:entry).tap { |entry| entry.instance_eval(&entries) }.fields
        end

        public

        def to_step_type
          StepType.new(id: @id, label: @label, fields: @fields, ports: @ports, awaits_input: @awaits_input, requirements: @requirements, behaviour: @behaviour, routing: @routing, naming_field: @naming_field, record_fields: @record_fields)
        end
      end
    end
  end
end
