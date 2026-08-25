require "test_helper"

module Alembic
  module Outputs
    class GroupedTest < ActiveSupport::TestCase
      def steps
        { "budget" => { "tag" => "money", "options" => [ { "value" => "high", "weight" => 5 } ] },
          "spend"  => { "tag" => "money", "options" => [ { "value" => "some", "weight" => 2 }, { "value" => "lots", "weight" => 4 } ] },
          "timing" => { "tag" => "speed", "options" => [ { "value" => "now", "weight" => 3 } ] },
          "loose"  => { "options" => [ { "value" => "x", "weight" => 9 } ] } }
      end

      def walked(state)
        Summary::Run.new(state: state, steps: steps)
      end

      def grouped(state, config = {})
        Grouped.output_type.compute(config, walked(state), {})
      end

      test "reports a share for each tag the run touched" do
        result = grouped({ "budget" => "high", "timing" => "now" })

        assert_equal [ "money", "speed" ], result.keys.sort
      end

      test "scores a tag by what its steps captured" do
        assert_equal 100, grouped({ "budget" => "high" })["money"]
      end

      test "a partly captured tag reports the share it captured" do
        assert_equal 78, grouped({ "budget" => "high", "spend" => "some" })["money"]
      end

      test "leaves out a step carrying no tag" do
        assert_not_includes grouped({ "loose" => "x" }).keys, nil
      end

      test "can be told which field carries the tag" do
        marked = { "budget" => { "area" => "money", "options" => [ { "value" => "high", "weight" => 5 } ] } }

        result = Grouped.output_type.compute({ "by" => "area" }, Summary::Run.new(state: { "budget" => "high" }, steps: marked), {})

        assert_equal({ "money" => 100 }, result)
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        Grouped.register(registry)

        assert_equal :grouped, registry.fetch("grouped").id
      end
    end
  end
end
