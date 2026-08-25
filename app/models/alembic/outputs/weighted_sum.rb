module Alembic
  module Outputs
    module WeightedSum
      def self.output_type
        Summary::OutputType.define(:weighted_sum) do
          label "Score"
          compute { |config, state, _so_far| WeightedSum.total(config, state) }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.total(config, state)
        state.sum { |step, value| config.dig("weights", step.to_s, value.to_s).to_i }
      end
    end
  end
end
