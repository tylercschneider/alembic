require "test_helper"

module Alembic
  module Flow
    class StepTypeTest < ActiveSupport::TestCase
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
