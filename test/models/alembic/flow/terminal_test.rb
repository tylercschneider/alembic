require "test_helper"

module Alembic
  module Flow
    class TerminalTest < ActiveSupport::TestCase
      test "ends the flow that reaches it" do
        assert_predicate Terminal.step_type, :ends_here?
      end
    end
  end
end
