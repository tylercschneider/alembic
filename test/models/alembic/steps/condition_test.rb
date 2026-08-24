require "test_helper"

module Alembic
  module Steps
    class ConditionTest < ActiveSupport::TestCase
      def branch(config)
        Flow::Node.new(id: "branch", type: "condition", config: config)
      end

      test "leaves by the yes port when the tested state equals the value" do
        node = branch({ "answer" => "budget", "equals" => "high" })

        assert_equal :yes, Condition.step_type.route(node, { "budget" => "high" })
      end

      test "leaves by the no port when the tested state differs from the value" do
        node = branch({ "answer" => "budget", "equals" => "high" })

        assert_equal :no, Condition.step_type.route(node, { "budget" => "low" })
      end

      test "leaves by the yes port when the tested state is in the set" do
        node = branch({ "answer" => "budget", "in" => [ "mid", "high" ] })

        assert_equal :yes, Condition.step_type.route(node, { "budget" => "high" })
      end

      test "leaves by the no port when the tested state is outside the set" do
        node = branch({ "answer" => "budget", "in" => [ "mid", "high" ] })

        assert_equal :no, Condition.step_type.route(node, { "budget" => "low" })
      end

      test "leaves by the no port when the tested step has no state yet" do
        node = branch({ "answer" => "budget", "equals" => "high" })

        assert_equal :no, Condition.step_type.route(node, {})
      end

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
