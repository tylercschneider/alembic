require "test_helper"

module Alembic
  module Steps
    class SwitchTest < ActiveSupport::TestCase
      def switch(config)
        Flow::Node.new(id: "fork", type: "switch", config: config)
      end

      test "declares the step it directs on" do
        assert_equal :previous_step, Switch.step_type.fields[:step]
      end

      test "directs on the values the step it names outputs" do
        assert_equal :step, Switch.step_type.outputs.first.from
      end

      test "directs by the answer the step it names gave" do
        assert_equal "high", Switch.step_type.route(switch({ "step" => "budget" }), { "budget" => "high" })
      end

      test "requires the step it directs on" do
        assert_equal [ "budget" ], Switch.step_type.requirements_for(switch({ "step" => "budget" }))
      end
    end
  end
end
