module Alembic
  module Outputs
    module WeightedSum
      def self.output_type
        Summary::OutputType.define(:weighted_sum) do
          label "Score"
          compute { |_config, run, _so_far| WeightedSum.total(run) }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.total(run)
        run.state.sum { |id, value| weight_of(run.step(id), value) }
      end

      def self.weight_of(step, value)
        chosen = Array(step["options"]).find { |option| option.is_a?(Hash) && option["value"] == value }

        chosen&.fetch("weight", nil).to_i
      end
    end
  end
end
