require "test_helper"

module Alembic
  module Summary
    class ReportTest < ActiveSupport::TestCase
      def registry
        @registry ||= Registry.new.tap do |built|
          built.register(OutputType.define(:tally) { label "Tally"; compute { |_c, state, _s| state.size } })
          built.register(OutputType.define(:twice) { compute { |config, _st, so_far| so_far[config["of"]] * 2 } })
        end
      end

      def report(outputs)
        Report.new({ "outputs" => outputs }, registry: registry)
      end

      test "names each output it produced" do
        results = report([ { "id" => "count", "type" => "tally" } ]).results({ "a" => 1 })

        assert_equal [ "count" ], results.map(&:id)
      end

      test "carries the value an output computed" do
        results = report([ { "id" => "count", "type" => "tally" } ]).results({ "a" => 1, "b" => 2 })

        assert_equal 2, results.first.value
      end

      test "labels an output from the type that produced it" do
        results = report([ { "id" => "count", "type" => "tally" } ]).results({})

        assert_equal "Tally", results.first.label
      end

      test "an output can name its own label" do
        results = report([ { "id" => "count", "type" => "tally", "label" => "How many" } ]).results({})

        assert_equal "How many", results.first.label
      end

      test "an output can read what an earlier one produced" do
        results = report([ { "id" => "count", "type" => "tally" },
                           { "id" => "doubled", "type" => "twice", "of" => "count" } ]).results({ "a" => 1, "b" => 2 })

        assert_equal 4, results.last.value
      end

      test "an output naming a type that was never registered fails clearly" do
        assert_raises UnknownOutputType do
          report([ { "id" => "x", "type" => "invented" } ]).results({})
        end
      end

      test "a summary with no outputs produces nothing" do
        assert_empty report([]).results({ "a" => 1 })
      end
    end
  end
end
