module Alembic
  module Flow
    class StepType
      def self.define(id, &declaration)
        Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
      end

      attr_reader :drawn_by, :id, :step_name, :fields, :labels, :choices, :limits, :checks, :record_fields, :record_labels, :naming_field, :naming, :drawn_from, :outputs_of, :outputs

      def initialize(id:, step_name:, fields:, awaits_input:, ends_here: false, begins_here: false, behaviour:, routing:, display: nil, drawn_by: nil, naming_field: nil, naming: nil, drawn_from: {}, outputs_of: {}, outputs: [], required: [], record_fields: {}, labels: {}, record_labels: {}, choices: {}, limits: {}, checks: {})
        @id = id
        @step_name = step_name
        @fields = fields
        @awaits_input = awaits_input
        @ends_here = ends_here
        @begins_here = begins_here
        @behaviour = behaviour
        @routing = routing
        @display = display
        @drawn_by = drawn_by
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

      def display_of(node)
        @display&.call(node)
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

      def acts?
        @behaviour.present?
      end

      def routes?
        @routing.present?
      end

      def requirements_for(node)
        naming_steps.map { |name| node.config[name.to_s] }.compact_blank
      end

      def naming_steps
        fields.select { |_name, type| type == :previous_step }.keys
      end

      def required
        fields.keys.select { |name| @required.include?(name) || naming_steps.include?(name) }
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
    end
  end
end
