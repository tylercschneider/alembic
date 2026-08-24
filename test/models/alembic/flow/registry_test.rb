require "test_helper"

module Alembic
  module Flow
    class RegistryTest < ActiveSupport::TestCase
      test "starts with no step types registered" do
        assert_empty Registry.new.step_types
      end

      test "finds a step type by the identifier a document uses" do
        registry = Registry.new
        registry.register(StepType.define(:question) {})

        assert_equal :question, registry.fetch("question").id
      end

      test "fails clearly for a step type that was never registered" do
        assert_raises UnknownStepType do
          Registry.new.fetch("question")
        end
      end
    end
  end
end
