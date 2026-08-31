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

        def record(id, value)
          @answers = @answers.merge(id.to_sym => value)
        end
      end
    end
  end
end
