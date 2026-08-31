module Alembic
  module Flow
    module Progress
      class Kept
        def initialize(run)
          @run = run
        end

        def recorded
          @run.recorded
        end
      end
    end
  end
end
