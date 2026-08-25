module Alembic
  module Outputs
    module Percentage
      def self.output_type
        Summary::OutputType.define(:percentage) do
          label "Share"
          compute { |_config, run, _so_far| Percentage.of(run, run.state.keys) }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.of(run, ids)
        offered = ids.sum { |id| most(run.step(id)) }
        return 0 if offered.zero?

        (captured(run, ids).to_f / offered * 100).round
      end

      def self.captured(run, ids)
        ids.sum { |id| WeightedSum.weight_of(run.step(id), run.state[id]) }
      end

      def self.most(step)
        Steps::Question.answers_of(step).filter_map { |option| option["weight"].to_i if option.is_a?(Hash) }.max.to_i
      end
    end
  end
end
