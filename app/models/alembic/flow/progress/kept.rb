module Alembic
  module Flow
    module Progress
      class Kept
        def initialize(run)
          @run = run
        end

        def definition
          @run.pinned_definition
        end

        def summary_of(state)
          return [] if @run.pinned_summary.blank?

          Summary::Report.new(@run.pinned_summary)
            .results(Summary::Run.new(state: state, steps: @run.pinned_steps))
        end

        def recorded
          @run.recorded
        end

        def record(id, value)
          @run.record(id.to_sym, value)
        end

        def finish(_state)
          @run
        end

        def discard_last
          @run.discard_last
        end
      end
    end
  end
end
