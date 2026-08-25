module Alembic
  module Outputs
    module Tally
      def self.output_type
        Summary::OutputType.define(:tally) do
          label "How many"
          compute { |config, run, _so_far| Tally.counted(run, config["tag"], config["by"].presence || "tag") }
        end
      end

      def self.register(registry = Summary.registry)
        registry.register(output_type)
      end

      def self.counted(run, tag, marker)
        answered = run.state.keys
        return answered.size if tag.blank?

        answered.count { |id| run.step(id)[marker] == tag }
      end
    end
  end
end
