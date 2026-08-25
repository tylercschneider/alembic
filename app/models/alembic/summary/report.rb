module Alembic
  module Summary
    class Report
      def initialize(configuration, registry: Summary.registry)
        @configuration = configuration.to_h
        @registry = registry
      end

      def results(state)
        produced = {}

        outputs.map do |output|
          output_type = @registry.fetch(output["type"])
          produced[output["id"]] = output_type.compute(output, state, produced)

          Result.new(id: output["id"], label: label_for(output, output_type), value: produced[output["id"]])
        end
      end

      private

      def outputs
        Array(@configuration["outputs"])
      end

      def label_for(output, output_type)
        output["label"].presence || output_type.label
      end
    end
  end
end
