require "test_helper"

module Alembic
  module Steps
    class ConditionTest < ActiveSupport::TestCase
      def branch(config)
        Flow::Node.new(id: "branch", type: "condition", config: config)
      end

      test "requires the step whose answer it tests" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal [ "budget" ], Condition.step_type.requirements_for(node)
      end

      test "requires nothing when it names no step to test" do
        assert_empty Condition.step_type.requirements_for(branch({}))
      end

      test "registers through the public step-type API" do
        registry = Flow::Registry.new

        Condition.register(registry)

        assert_equal :condition, registry.fetch("condition").id
      end

      test "leaves by the yes port when the step gave the answer it tests for" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal :yes, Condition.step_type.route(node, { "budget" => "high" })
      end

      test "leaves by the no port when the step gave a different answer" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal :no, Condition.step_type.route(node, { "budget" => "low" })
      end

      test "leaves by the no port when the step has not been answered yet" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal :no, Condition.step_type.route(node, {})
      end

      test "does not await external input" do
        assert_not_predicate Condition.step_type, :awaits_input?
      end

      test "declares the step whose answer it tests as one that comes before it" do
        assert_equal :previous_step, Condition.step_type.fields[:step]
      end

      test "declares the answer it tests for" do
        assert_equal :string, Condition.step_type.fields[:answer]
      end

      test "declares two named output ports" do
        assert_equal [ :yes, :no ], Condition.step_type.ports
      end
    end
  end
end
