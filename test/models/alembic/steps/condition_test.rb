require "test_helper"

module Alembic
  module Steps
    class ConditionTest < ActiveSupport::TestCase
      def flow_core_sources
        Dir[Engine.root.join("app/models/alembic/flow.rb")] +
          Dir[Engine.root.join("app/models/alembic/flow/**/*.rb")]
      end

      def branch(config)
        Flow::Node.new(id: "branch", type: "condition", config: config)
      end

      test "there are flow core sources to check" do
        assert_not_empty flow_core_sources
      end

      test "the flow core never mentions the condition step type" do
        naming_it = flow_core_sources.select { |source| File.read(source).match?(/condition/i) }

        assert_empty naming_it.map { |source| source.split("/models/").last }
      end

      test "requires the step whose state it tests" do
        node = branch({ "answer" => "budget", "equals" => "high" })

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
