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
        step_type = StepType.define(:agent) { }

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
        step_type = StepType.define(:agent) { }

        assert_nil step_type.route(node_testing("a"), {})
      end

      test "derives its required predecessors from a node's configuration" do
        step_type = StepType.define(:condition) { requires { |node| [ node.config["answer"] ] } }

        assert_equal [ "a" ], step_type.requirements_for(node_testing("a"))
      end

      test "requires nothing when it declares no requirements" do
        step_type = StepType.define(:agent) { }

        assert_empty step_type.requirements_for(node_testing("a"))
      end

      test "awaits external input when it declares so" do
        step_type = StepType.define(:question) { awaits_input }

        assert_predicate step_type, :awaits_input?
      end

      test "does not await external input by default" do
        step_type = StepType.define(:agent) { }

        assert_not_predicate step_type, :awaits_input?
      end

      test "declares named output ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_equal [ :yes, :no ], step_type.ports
      end

      test "has a single unnamed output when it declares no ports" do
        step_type = StepType.define(:agent) { }

        assert_predicate step_type, :single_output?
      end

      test "does not have a single unnamed output once it names ports" do
        step_type = StepType.define(:branch) { outputs :yes, :no }

        assert_not_predicate step_type, :single_output?
      end

      test "can declare which field names an instance of it" do
        step_type = StepType.define(:ask) { setting :text, type: :text; names_by :text }

        assert_equal :text, step_type.naming_field
      end

      test "names an instance by nothing unless it says so" do
        step_type = StepType.define(:branch) { setting :answer, type: :string }

        assert_nil step_type.naming_field
      end

      test "declares a field holding a list of records" do
        step_type = StepType.define(:ask) { setting :options, type: :records, of: { value: :string, weight: :number } }

        assert_equal :records, step_type.fields[:options]
      end

      test "carries what each record in the list holds" do
        step_type = StepType.define(:ask) { setting :options, type: :records, of: { value: :string, weight: :number } }

        assert_equal({ value: :string, weight: :number }, step_type.record_fields[:options])
      end

      test "refuses a list of records that does not say what a record holds" do
        assert_raises UnknownFieldType do
          StepType.define(:ask) { setting :options, type: :records }
        end
      end

      test "refuses a record holding a type outside the vocabulary" do
        assert_raises UnknownFieldType do
          StepType.define(:ask) { setting :options, type: :records, of: { value: :wormhole } }
        end
      end

      test "carries the fields it declares" do
        step_type = StepType.define(:agent) { setting :prompt, type: :text }

        assert_equal({ prompt: :text }, step_type.fields)
      end

      test "refuses a field type outside the vocabulary" do
        assert_raises UnknownFieldType do
          StepType.define(:agent) { setting :prompt, type: :wormhole }
        end
      end

      test "carries the label it was given" do
        step_type = StepType.define(:agent) { label "Agent call" }

        assert_equal "Agent call", step_type.label
      end

      test "falls back to its identifier when no label is given" do
        step_type = StepType.define(:agent) { }

        assert_equal "agent", step_type.label
      end

      test "carries the identifier it was defined with" do
        step_type = StepType.define(:agent) { label "Agent call" }

        assert_equal :agent, step_type.id
      end

      test "declares a configurable value with setting" do
        step_type = StepType.define(:probe) { setting :prompt, type: :text }

        assert_equal({ prompt: :text }, step_type.fields)
      end

      test "refuses a setting whose type it does not know" do
        assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :prompt, type: :nonsense } }
      end
    end
  end
end
