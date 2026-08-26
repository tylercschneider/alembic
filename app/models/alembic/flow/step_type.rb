module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :id, :step_name, :fields, :labels, :choices, :limits, :checks, :record_fields, :record_labels, :naming_field, :naming, :drawn_from, :outputs_of, :outputs, :required

      def initialize(id:, step_name:, fields:, awaits_input:, ends_here: false, begins_here: false, requirements:, behaviour:, routing:, naming_field: nil, naming: nil, drawn_from: {}, outputs_of: {}, outputs: [], required: [], record_fields: {}, labels: {}, record_labels: {}, choices: {}, limits: {}, checks: {})
        @id = id
        @step_name = step_name
        @fields = fields
        @awaits_input = awaits_input
        @ends_here = ends_here
        @begins_here = begins_here
        @requirements = requirements
        @behaviour = behaviour
        @routing = routing
        @naming_field = naming_field
        @naming = naming
        @drawn_from = drawn_from
        @outputs_of = outputs_of
        @outputs = outputs
        @required = required
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

      def name_of(node)
        @naming&.call(node).presence || node.config[naming_field.to_s].presence
      end

      def routes?
        @routing.present?
      end

      def requirements_for(node)
        Array(@requirements&.call(node))
      end

      def values_of(name, node)
        outputs.find { |output| output.name.to_s == name.to_s }&.values_for(node).to_a
      end

      def awaits_input?
        @awaits_input
      end

      def ends_here?
        @ends_here
      end

      def begins_here?
        @begins_here
      end

      def coerce(config)
        config.to_h.to_h { |name, value| [ name, cast(fields[name.to_sym], value, record_fields[name.to_sym]) ] }
      end

      def objections(config)
        config.to_h.flat_map { |name, value| objections_to(name.to_sym, value) }.compact
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
          @drawn_from = {}
          @outputs_of = {}
          @declared_outputs = []
          @required = []
          @awaits_input = false
          @ends_here = false
          @begins_here = false
        end

        def requires(&derivation)
          @requirements = derivation
        end

        def output(name, type: :string, label: nil, values: nil, from: nil)
          @declared_outputs += [ Output.new(name: name, type: type, label: label, values: values, from: from) ]
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

        def ends_here
          @ends_here = true
        end

        def begins_here
          @begins_here = true
        end

        def names_by(field = nil, &naming)
          @naming_field = field
          @naming = naming
        end

        def setting(name, type: nil, from: nil, outputs_of: nil, label: nil, options: nil, limit: nil, check: nil, required: false, &entries)
          type ||= :from_step if from
          type ||= :from_step if outputs_of
          raise UnknownFieldType, "#{type} is not one of #{FIELD_TYPES.join(', ')}" unless FIELD_TYPES.include?(type)

          @drawn_from[name] = from if from
          @outputs_of[name] = outputs_of if outputs_of
          @required += [ name ] if required

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
          StepType.new(id: @id, step_name: @step_name, fields: @fields, awaits_input: @awaits_input, ends_here: @ends_here, begins_here: @begins_here, requirements: @requirements, behaviour: @behaviour, routing: @routing, naming_field: @naming_field, naming: @naming, drawn_from: @drawn_from, outputs_of: @outputs_of, outputs: @declared_outputs, required: @required, record_fields: @record_fields, labels: @labels, record_labels: @record_labels, choices: @choices, limits: @limits, checks: @checks)
        end
      end
    end
  end
end
