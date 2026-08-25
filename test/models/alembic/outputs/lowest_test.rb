require "test_helper"

module Alembic
  module Outputs
    class LowestTest < ActiveSupport::TestCase
      def shares
        { "money" => 90, "speed" => 20, "care" => 55 }
      end

      def lowest(config)
        Lowest.output_type.compute(config, Summary::Run.new(state: {}), { "areas" => shares })
      end

      test "names the weakest of what it reads" do
        assert_equal [ "speed" ], lowest({ "of" => "areas", "count" => 1 })
      end

      test "names as many as it is asked for, weakest first" do
        assert_equal [ "speed", "care" ], lowest({ "of" => "areas", "count" => 2 })
      end

      test "names one when it is not told how many" do
        assert_equal [ "speed" ], lowest({ "of" => "areas" })
      end

      test "names nothing when what it reads is empty" do
        assert_empty Lowest.output_type.compute({ "of" => "areas" }, Summary::Run.new(state: {}), { "areas" => {} })
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        Lowest.register(registry)

        assert_equal :lowest, registry.fetch("lowest").id
      end
    end
  end
end
