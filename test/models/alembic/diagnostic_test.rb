require "test_helper"

module Alembic
  class DiagnosticTest < ActiveSupport::TestCase
    test "reports when it is published" do
      assert Diagnostic.new(status: :published).published?
    end

    test "reports its kind" do
      assert Diagnostic.new(kind: :scored).scored?
    end

    test "is invalid without a slug" do
      assert_not Diagnostic.new(slug: nil).valid?
    end

    test "selects the band whose ceiling the score falls under" do
      assert_equal "Flying blind", alembic_diagnostics(:business_scorecard).band_for(30).name
    end

    test "falls through to the open-ended band for high scores" do
      assert_equal "Well instrumented", alembic_diagnostics(:business_scorecard).band_for(90).name
    end

    test "places by applying the results of firing rules" do
      diagnostic = alembic_diagnostics(:stats_ladder)
      diagnostic.rules.create!(position: 1).results << alembic_results(:tier_event_log)

      assert_equal "Event log + rollups", diagnostic.place({})["tier"].title
    end
  end
end
