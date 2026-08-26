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
    end
  end
end
