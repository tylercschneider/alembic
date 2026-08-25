module Alembic
  module Outputs
    module Band
      def self.output_type
        Summary::OutputType.define(:band) do
          label "Band"
          compute { |config, _run, so_far| Band.covering(config, so_far[config["of"]]) }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.covering(config, number)
        ordered = Array(config["bands"]).sort_by { |band| band["ceiling"] || Float::INFINITY }

        ordered.find { |band| band["ceiling"].nil? || number < band["ceiling"] }&.fetch("name", nil)
      end
    end
  end
end
