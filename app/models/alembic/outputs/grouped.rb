module Alembic
  module Outputs
    module Grouped
      def self.output_type
        Summary::OutputType.define(:grouped) do
          label "By area"
          compute { |config, run, _so_far| Grouped.shares(run, config["by"].presence) }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.bucket(step, marker)
        marker ? step[marker] : Steps::Question.category_of(step)
      end

      def self.shares(run, marker)
        run.state.keys.group_by { |id| Grouped.bucket(run.step(id), marker) }
          .except(nil)
          .transform_values { |ids| Percentage.of(run, ids) }
      end
    end
  end
end
