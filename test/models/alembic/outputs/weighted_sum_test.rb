require "test_helper"

module Alembic
  module Outputs
    class WeightedSumTest < ActiveSupport::TestCase
      def steps
        { "budget" => { "options" => [ { "value" => "low", "weight" => 1 }, { "value" => "high", "weight" => 5 } ] },
          "team" => { "options" => [ { "value" => "yes", "weight" => 3 }, { "value" => "no" } ] } }
      end

      def summed(state)
        WeightedSum.output_type.compute({}, Summary::Run.new(state: state, steps: steps), {})
      end

      test "adds up the weight each chosen option carries" do
        assert_equal 8, summed({ "budget" => "high", "team" => "yes" })
      end

      test "counts nothing for an option carrying no weight" do
        assert_equal 5, summed({ "budget" => "high", "team" => "no" })
      end

      test "counts nothing for an answer to a step it does not know" do
        assert_equal 5, summed({ "budget" => "high", "invented" => "x" })
      end

      test "reads a weight written by a form as text" do
        written = { "budget" => { "options" => [ { "value" => "high", "weight" => "5" } ] } }

        assert_equal 5, WeightedSum.output_type.compute({}, Summary::Run.new(state: { "budget" => "high" }, steps: written), {})
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        WeightedSum.register(registry)

        assert_equal :weighted_sum, registry.fetch("weighted_sum").id
      end
    end
  end
end
