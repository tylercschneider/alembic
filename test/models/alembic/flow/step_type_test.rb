require "test_helper"

module Alembic
  module Flow
    class StepTypeTest < ActiveSupport::TestCase
      def node_testing(id)
        Node.new(id: "branch", type: "condition", config: { "answer" => id })
      end

      test "carries the behaviour it declares" do
        step_type = StepType.define(:agent) { process { |node, state| { "out" => state["in"] } } }

        assert_equal({ "out" => 1 }, step_type.process(node_testing("a"), { "in" => 1 }))
      end

      test "contributes nothing when it declares no behaviour" do
        step_type = StepType.define(:agent) {}

        assert_nil step_type.process(node_testing("a"), {})
      end

      test "carries the routing it declares separately from its behaviour" do
        step_type = StepType.define(:branch) do
          outputs :yes, :no
          route { |node, state| state["ok"] ? :yes : :no }
        end

        assert_equal :no, step_type.route(node_testing("a"), { "ok" => false })
      end

      test "chooses no port when it declares no routing" do
        step_type = StepType.define(:agent) {}

        assert_nil step_type.route(node_testing("a"), {})
      end

      test "derives its required predecessors from a node's configuration" do
        step_type = StepType.define(:condition) { requires { |node| [ node.config["answer"] ] } }

        assert_equal [ "a" ], step_type.requirements_for(node_testing("a"))
      end

      test "requires nothing when it declares no requirements" do
        step_type = StepType.define(:agent) {}

        assert_empty step_type.requirements_for(node_testing("a"))
      end

      test "awaits external input when it declares so" do
        step_type = StepType.define(:question) { awaits_input }

        assert_predicate step_type, :awaits_input?
      end

      test "does not await external input by default" do
        step_type = StepType.define(:agent) {}

        assert_not_predicate step_type, :awaits_input?
      end

      test "declares named output ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_equal [ :yes, :no ], step_type.ports
      end

      test "has a single unnamed output when it declares no ports" do
        step_type = StepType.define(:agent) {}

        assert_predicate step_type, :single_output?
      end

      test "does not have a single unnamed output once it names ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_not_predicate step_type, :single_output?
      end

      test "carries the fields it declares" do
        step_type = StepType.define(:agent) { field :prompt, :text }

        assert_equal({ prompt: :text }, step_type.fields)
      end

      test "refuses a field type outside the vocabulary" do
        assert_raises UnknownFieldType do
          StepType.define(:agent) { field :prompt, :wormhole }
        end
      end

      test "carries the label it was given" do
        step_type = StepType.define(:agent) { label "Agent call" }

        assert_equal "Agent call", step_type.label
      end

      test "falls back to its identifier when no label is given" do
        step_type = StepType.define(:agent) {}

        assert_equal "agent", step_type.label
      end

      test "carries the identifier it was defined with" do
        step_type = StepType.define(:agent) { label "Agent call" }

        assert_equal :agent, step_type.id
      end
    end
  end
end
