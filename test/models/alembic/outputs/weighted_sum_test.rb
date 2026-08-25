require "test_helper"

module Alembic
  module Outputs
    class WeightedSumTest < ActiveSupport::TestCase
      def weighted(weights)
        { "weights" => weights }
      end

      def summed(config, state)
        WeightedSum.output_type.compute(config, state, {})
      end

      test "adds up the weight of each answer given" do
        config = weighted({ "budget" => { "high" => 5 }, "team" => { "yes" => 3 } })

        assert_equal 8, summed(config, { "budget" => "high", "team" => "yes" })
      end

      test "counts nothing for an answer with no weight configured" do
        config = weighted({ "budget" => { "high" => 5 } })

        assert_equal 5, summed(config, { "budget" => "high", "team" => "unweighted" })
      end

      test "counts nothing for a step with no weights at all" do
        assert_equal 0, summed(weighted({}), { "budget" => "high" })
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        WeightedSum.register(registry)

        assert_equal :weighted_sum, registry.fetch("weighted_sum").id
      end
    end
  end
end
