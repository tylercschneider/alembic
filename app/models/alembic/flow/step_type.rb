module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :step_name, :fields, :labels, :record_fields, :ports, :naming_field

      def initialize(id:, step_name:, fields:, ports:, awaits_input:, requirements:, behaviour:, routing:, naming_field: nil, record_fields: {}, labels: {})
        @id = id
        @step_name = step_name
        @fields = fields
        @ports = ports
        @awaits_input = awaits_input
        @requirements = requirements
        @behaviour = behaviour
        @routing = routing
        @naming_field = naming_field
        @record_fields = record_fields
        @labels = labels
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

      def coerce(config)
        config.to_h.to_h { |name, value| [ name, cast(fields[name.to_sym], value, record_fields[name.to_sym]) ] }
      end

      def single_output?
        ports.empty?
      end

      private

      def cast(type, value, holds = nil)
        case type
        when :integer then Integer(value, exception: false)
        when :float then Float(value, exception: false)
        when :boolean then ActiveModel::Type::Boolean.new.cast(value).present?
        when :list then Array(value).map { |entry| cast_entry(entry, holds.to_h) }
        else value
        end
      end

      def cast_entry(entry, holds)
        entry.to_h.to_h { |name, value| [ name, cast(holds[name.to_sym], value) ] }
      end

      public

      class Declaration
        def initialize(id)
          @id = id
          @step_name = id.to_s
          @fields = {}
          @labels = {}
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

        def step_name(value)
          @step_name = value
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

        def setting(name, type:, label: nil, &entries)
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @record_fields[name] = holdings(entries) if type == :list
          @labels[name] = label.presence || name.to_s.humanize
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
          StepType.new(id: @id, step_name: @step_name, fields: @fields, ports: @ports, awaits_input: @awaits_input, requirements: @requirements, behaviour: @behaviour, routing: @routing, naming_field: @naming_field, record_fields: @record_fields, labels: @labels)
        end
      end
    end
  end
end
