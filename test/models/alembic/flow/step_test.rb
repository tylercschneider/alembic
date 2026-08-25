require "test_helper"

module Alembic
  module Flow
    class StepTest < ActiveSupport::TestCase
      class Probe
        include Flow::Step

        label "Probe step"
      end

      test "derives its id from the class name" do
        assert_equal :probe, Probe.step_type.id
      end

      test "carries a declaration made at class level" do
        assert_equal "Probe step", Probe.step_type.label
      end

      test "registers itself without defining a register method" do
        registry = Registry.new

        Probe.register(registry)

        assert registry.registered?(:probe)
      end
    end
  end
end
