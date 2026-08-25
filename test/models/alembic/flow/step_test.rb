require "test_helper"

module Alembic
  module Flow
    class StepTest < ActiveSupport::TestCase
      class Probe
        include Flow::Step
      end

      test "derives its id from the class name" do
        assert_equal :probe, Probe.step_type.id
      end
    end
  end
end
