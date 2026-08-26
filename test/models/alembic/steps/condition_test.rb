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

      test "decides true when the step gave the answer it tests for" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal true, Condition.step_type.route(node, { "budget" => "high" })
      end

      test "decides false when the step gave a different answer" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal false, Condition.step_type.route(node, { "budget" => "low" })
      end

      test "decides false when the step has not been answered yet" do
        node = branch({ "step" => "budget", "answer" => "high" })

        assert_equal false, Condition.step_type.route(node, {})
      end

      test "does not await external input" do
        assert_not_predicate Condition.step_type, :awaits_input?
      end

      test "declares the step whose answer it tests as one that comes before it" do
        assert_equal :previous_step, Condition.step_type.fields[:step]
      end

      test "draws the answer it tests from the step it names" do
        assert_equal :step, Condition.step_type.drawn_from[:answer]
      end

      test "declares the result it decides as an output" do
        assert_equal [ :result ], Condition.step_type.outputs.map(&:name)
      end

      test "cannot run without the step, comparison and answer it tests" do
        assert_equal [ :step, :comparison, :answer ], Condition.step_type.required
      end

      test "offers a comparison deciding which way the test falls" do
        assert_equal [ "is", "is not" ], Condition.step_type.choices[:comparison]
      end

      test "decides false when the step gave the answer it tests for and is not" do
        node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

        assert_equal false, Condition.step_type.route(node, { "budget" => "high" })
      end

      test "decides true when the step gave a different answer and is not" do
        node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

        assert_equal true, Condition.step_type.route(node, { "budget" => "low" })
      end

      test "names itself by the test it makes" do
        node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

        assert_equal "budget is not high", Condition.step_type.name_of(node)
      end
    end
  end
end
