module Alembic
  module Summary
    Run = Data.define(:state, :steps) do
      def initialize(state:, steps: {})
        super
      end

      def step(id)
        steps[id.to_s].to_h
      end
    end
  end
end
