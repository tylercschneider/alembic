require "test_helper"

module Alembic
  module Flow
    class DrawingTest < ActiveSupport::TestCase
      def registry
        @registry ||= Registry.new.tap do |built|
          built.register(StepType.define(:plain) { awaits_input })
          built.register(StepType.define(:tiled) { drawn_by "flows/steps/tiles" })
        end
      end

      def node(type)
        Node.new(id: "a", type: type, config: {})
      end

      test "draws a step with the template its own type names" do
        assert_equal "flows/steps/tiles", Drawing.of(node("tiled"), registry)
      end
    end
  end
end
