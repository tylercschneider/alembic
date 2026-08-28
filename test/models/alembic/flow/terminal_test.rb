require "test_helper"

module Alembic
  module Flow
    class TerminalTest < ActiveSupport::TestCase
      test "ends the flow that reaches it" do
        assert_predicate Terminal.step_type, :ends_here?
      end

      test "declares a setting for the heading a run finishing here shows" do
        assert_equal :string, Terminal.step_type.fields[:heading]
      end

      test "is registered for a flow to use" do
        assert_equal :terminal, Flow.registry.fetch("terminal").id
      end
    end
  end
end
