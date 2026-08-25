require "test_helper"

module Alembic
  module Outputs
    class TallyTest < ActiveSupport::TestCase
      def steps
        { "budget" => { "tag" => "money" }, "spend" => { "tag" => "money" }, "timing" => { "tag" => "speed" } }
      end

      def counted(config, state)
        Tally.output_type.compute(config, Summary::Run.new(state: state, steps: steps), {})
      end

      test "counts the steps a run answered" do
        assert_equal 3, counted({}, { "budget" => "a", "spend" => "b", "timing" => "c" })
      end

      test "counts only the steps carrying the tag it was given" do
        assert_equal 2, counted({ "tag" => "money" }, { "budget" => "a", "spend" => "b", "timing" => "c" })
      end

      test "counts none when no step carries that tag" do
        assert_equal 0, counted({ "tag" => "invented" }, { "budget" => "a" })
      end

      test "can be told which field carries the tag" do
        marked = { "budget" => { "area" => "money" } }

        assert_equal 1, Tally.output_type.compute({ "by" => "area", "tag" => "money" },
                                                  Summary::Run.new(state: { "budget" => "a" }, steps: marked), {})
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        Tally.register(registry)

        assert_equal :tally, registry.fetch("tally").id
      end
    end
  end
end
