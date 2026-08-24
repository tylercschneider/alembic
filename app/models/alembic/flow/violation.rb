module Alembic
  module Flow
    Violation = Data.define(:node, :problem, :detail) do
      def initialize(node:, problem:, detail: nil)
        super
      end
    end
  end
end
