module Alembic
  module Flow
    module Progress
      class Loose
        def initialize(flow, answers)
          @flow = flow
          @answers = answers.to_h.symbolize_keys
        end

        def recorded
          @answers
        end
      end
    end
  end
end
