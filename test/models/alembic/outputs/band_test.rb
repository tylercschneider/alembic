require "test_helper"

module Alembic
  module Outputs
    class BandTest < ActiveSupport::TestCase
      def bands
        { "of" => "score", "bands" => [ { "ceiling" => 5, "name" => "Modest" },
                                        { "ceiling" => 10, "name" => "Fair" },
                                        { "name" => "Generous" } ] }
      end

      def banded(score)
        Band.output_type.compute(bands, Summary::Run.new(state: {}), { "score" => score })
      end

      test "names the first band a number falls under" do
        assert_equal "Modest", banded(3)
      end

      test "passes a number over one ceiling to the next band" do
        assert_equal "Fair", banded(7)
      end

      test "the band with no ceiling catches anything above the rest" do
        assert_equal "Generous", banded(99)
      end

      test "a number on a ceiling belongs to the band above it" do
        assert_equal "Fair", banded(5)
      end

      test "names nothing when no band is configured" do
        assert_nil Band.output_type.compute({ "of" => "score", "bands" => [] }, Summary::Run.new(state: {}), { "score" => 3 })
      end

      test "registers through the public output API" do
        registry = Summary::Registry.new

        Band.register(registry)

        assert_equal :band, registry.fetch("band").id
      end
    end
  end
end
