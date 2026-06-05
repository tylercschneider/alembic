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

    test "the next question is the first applicable unanswered one" do
      assert_equal "need", alembic_diagnostics(:stats_ladder).next_question({}).key
    end

    test "the next question follows the branch the answers open" do
      assert_equal "read", alembic_diagnostics(:stats_ladder).next_question({ "need" => "now" }).key
    end

    test "complete when no applicable question remains" do
      assert alembic_diagnostics(:stats_ladder).complete?({ "need" => "trend" })
    end

    test "scores by summing the weights of the selected options" do
      diagnostic = Diagnostic.create!(slug: "scoring", kind: :scored, status: :draft)
      question = diagnostic.questions.create!(key: "q1", position: 1)
      question.options.create!(value: "yes", weight: 2)
      question.options.create!(value: "no", weight: 0)

      assert_equal 2, diagnostic.score({ "q1" => "yes" })
    end

    test "the scored result is the band for the total" do
      assert_equal "Flying blind", alembic_diagnostics(:business_scorecard).result_for({}).name
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

    test "a later rule overrides an earlier one on the same slot" do
      diagnostic = alembic_diagnostics(:stats_ladder)
      lossy = diagnostic.results.create!(slot: :level, key: "l0", title: "Telemetry sink", position: 1)
      diagnostic.rules.create!(position: 1).results << lossy
      diagnostic.rules.create!(position: 2).results << alembic_results(:level_outbox)

      assert_equal "Outbox · durable", diagnostic.place({})["level"].title
    end
  end
end
