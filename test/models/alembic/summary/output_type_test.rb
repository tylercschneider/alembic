require "test_helper"

module Alembic
  module Summary
    class OutputTypeTest < ActiveSupport::TestCase
      test "carries the identifier it was defined with" do
        assert_equal :tally, OutputType.define(:tally) { label "Tally" }.id
      end

      test "carries the label it was given" do
        assert_equal "Tally", OutputType.define(:tally) { label "Tally" }.label
      end

      test "falls back to its identifier when no label is given" do
        assert_equal "tally", OutputType.define(:tally) { }.label
      end

      test "computes a value from a run's state" do
        output_type = OutputType.define(:tally) { compute { |_config, run, _so_far| run.state.size } }

        assert_equal 2, output_type.compute({}, Run.new(state: { "a" => 1, "b" => 2 }), {})
      end

      test "computes a value from what earlier outputs produced" do
        output_type = OutputType.define(:double) { compute { |config, _run, so_far| so_far[config["of"]] * 2 } }

        assert_equal 10, output_type.compute({ "of" => "score" }, Run.new(state: {}), { "score" => 5 })
      end

      test "produces nothing when it declares no computation" do
        assert_nil OutputType.define(:empty) { }.compute({}, {}, {})
      end
    end
  end
end
