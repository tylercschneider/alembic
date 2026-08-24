require "test_helper"

module Alembic
  module Steps
    class ConditionTest < ActiveSupport::TestCase
      test "does not await external input" do
        assert_not_predicate Condition.step_type, :awaits_input?
      end

      test "declares the step whose state it tests" do
        assert_equal :string, Condition.step_type.fields[:answer]
      end

      test "declares the value it tests for equality" do
        assert_equal :string, Condition.step_type.fields[:equals]
      end

      test "declares the set it tests for membership" do
        assert_equal :list, Condition.step_type.fields[:in]
      end

      test "declares two named output ports" do
        assert_equal [ :yes, :no ], Condition.step_type.ports
      end
    end
  end
end
