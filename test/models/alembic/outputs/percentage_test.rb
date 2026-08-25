require "test_helper"

module Alembic
  module Outputs
    class PercentageTest < ActiveSupport::TestCase
      def steps
        { "budget" => { "options" => [ { "value" => "low", "weight" => 1 }, { "value" => "high", "weight" => 5 } ] },
          "team" => { "options" => [ { "value" => "no", "weight" => 0 }, { "value" => "yes", "weight" => 3 } ] } }
      end

      def share(state)
        Percentage.output_type.compute({}, Summary::Run.new(state: state, steps: steps), {})
      end

      test "capturing everything on offer is a full share" do
        assert_equal 100, share({ "budget" => "high", "team" => "yes" })
      end

      test "capturing nothing on offer is no share" do
        assert_equal 0, share({ "budget" => nil, "team" => "no" })
      end

      test "capturing some of what was on offer is that share of it" do
        assert_equal 63, share({ "budget" => "high", "team" => "no" })
      end

      test "only the steps a run reached count toward what was on offer" do
        assert_equal 100, share({ "team" => "yes" })
      end

      test "no share is reported when nothing was on offer" do
        assert_equal 0, Percentage.output_type.compute({}, Summary::Run.new(state: { "a" => "b" }), {})
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        Percentage.register(registry)

        assert_equal :percentage, registry.fetch("percentage").id
      end
    end
  end
end
