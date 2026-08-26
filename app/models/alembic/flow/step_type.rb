module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :step_name, :fields, :labels, :choices, :limits, :checks, :record_fields, :record_labels, :ports, :naming_field, :drawn_from, :outputs

      def initialize(id:, step_name:, fields:, ports:, awaits_input:, requirements:, offerings:, behaviour:, routing:, naming_field: nil, drawn_from: {}, outputs: [], record_fields: {}, labels: {}, record_labels: {}, choices: {}, limits: {}, checks: {})
        @id = id
        @step_name = step_name
        @fields = fields
        @ports = ports
        @awaits_input = awaits_input
        @requirements = requirements
        @offerings = offerings
        @behaviour = behaviour
        @routing = routing
        @naming_field = naming_field
        @drawn_from = drawn_from
        @outputs = outputs
        @record_fields = record_fields
        @labels = labels
        @record_labels = record_labels
        @choices = choices
        @limits = limits
        @checks = checks
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

      def offerings_for(node)
        Array(@offerings&.call(node))
      end

      def awaits_input?
        @awaits_input
      end

      def coerce(config)
        config.to_h.to_h { |name, value| [ name, cast(fields[name.to_sym], value, record_fields[name.to_sym]) ] }
      end

      def objections(config)
        config.to_h.flat_map { |name, value| objections_to(name.to_sym, value) }.compact
      end

      def single_output?
        ports.empty?
      end

      private

      def objections_to(name, value)
        [ unoffered(name, value), over_limit(name, value), refused(name, value) ]
      end

      def unoffered(name, value)
        offered = choices[name]
        return unless offered

        stray = Array(value).find { |chosen| offered.exclude?(chosen) }
        "#{labels[name]} does not offer #{stray}" if stray
      end

      def over_limit(name, value)
        allowed = limits[name]
        return unless allowed && Array(value).size > allowed

        "#{labels[name]} takes at most #{allowed}"
      end

      def refused(name, value)
        checks[name]&.call(value)
      end

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
          @record_labels = {}
          @choices = {}
          @limits = {}
          @checks = {}
          @ports = []
          @drawn_from = {}
          @declared_outputs = []
          @awaits_input = false
        end

        def requires(&derivation)
          @requirements = derivation
        end

        def output(name, label: nil)
          @declared_outputs += [ Output.new(name: name, label: label) ]
        end

        def offers(&derivation)
          @offerings = derivation
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

        def ports(*names)
          @ports = names
        end

        def setting(name, type: nil, from: nil, label: nil, options: nil, limit: nil, check: nil, &entries)
          type ||= :from_step if from
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @drawn_from[name] = from if from

          declare_entries(name, entries) if type == :list
          declare_choices(name, type, options)
          @limits[name] = limit if limit
          @checks[name] = check if check
          @labels[name] = label.presence || name.to_s.humanize
          @fields[name] = type
        end

        protected

        attr_reader :fields, :labels

        private

        def declare_choices(name, type, options)
          return @choices[name] = options if options.present?
          raise UnknownFieldType, "a #{type} must offer options" if %i[select multi_select].include?(type)
        end

        def declare_entries(name, entries)
          raise UnknownFieldType, "a list must say what an entry holds" if entries.nil?

          declared = Declaration.new(:entry).tap { |entry| entry.instance_eval(&entries) }
          @record_fields[name] = declared.fields
          @record_labels[name] = declared.labels
        end

        public

        def to_step_type
          StepType.new(id: @id, step_name: @step_name, fields: @fields, ports: @ports, awaits_input: @awaits_input, requirements: @requirements, offerings: @offerings, behaviour: @behaviour, routing: @routing, naming_field: @naming_field, drawn_from: @drawn_from, outputs: @declared_outputs, record_fields: @record_fields, labels: @labels, record_labels: @record_labels, choices: @choices, limits: @limits, checks: @checks)
        end
      end
    end
  end
end
