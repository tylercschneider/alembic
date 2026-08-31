module Alembic
  module Flow
    module Progress
      def self.for(flow, run: nil, answers: {})
        return Kept.new(run) if run

        Loose.new(flow, answers)
      end
    end
  end
end
