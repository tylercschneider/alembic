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

    test "stores a definition document" do
      assert_equal({ "slug" => "x" }, Diagnostic.new(definition: { "slug" => "x" }).definition)
    end

    test "builds a guide from its definition" do
      assert_equal "demo", Diagnostic.new(definition: { "slug" => "demo" }).to_guide.slug
    end

    test "stores guide copy and placement attributes" do
      diagnostic = Diagnostic.new(kicker: "k", headline: "h", blurb: "b", start_label: "s", resolver_key: "r")

      assert_equal [ "k", "h", "b", "s", "r" ], [ diagnostic.kicker, diagnostic.headline, diagnostic.blurb, diagnostic.start_label, diagnostic.resolver_key ]
    end

    test "compiling writes the rows into the definition" do
      diagnostic = Diagnostic.create!(slug: "demo", headline: "Compiled")

      diagnostic.compile!

      assert_equal "Compiled", diagnostic.definition["headline"]
    end

    test "reverting decompiles the definition into rows" do
      diagnostic = Diagnostic.create!(slug: "demo", definition: { "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      diagnostic.revert!

      assert_equal [ "need" ], diagnostic.questions.ordered.map(&:key)
    end

    test "reverting then compiling round-trips the bundled definition" do
      definition = Alembic.bundled_definition("stats-system-ladder")
      diagnostic = alembic_diagnostics(:stats_ladder)
      diagnostic.update!(definition: definition)

      diagnostic.revert!
      diagnostic.compile!

      assert_equal definition, diagnostic.definition
    end

    test "compiling then reverting round-trips a scored diagnostic's bands and weights" do
      diagnostic = Diagnostic.create!(slug: "scored", kind: "scored")
      question = diagnostic.questions.create!(key: "need", text: "Need?", position: 1)
      question.options.create!(value: "yes", label: "Yes", weight: 3, position: 1)
      diagnostic.bands.create!(ceiling: 10, name: "Starter", description: "Just beginning.")

      diagnostic.compile!
      compiled = diagnostic.definition
      diagnostic.revert!
      diagnostic.compile!

      assert_equal compiled, diagnostic.definition
    end

    test "reverting then compiling round-trips a domain-scored definition" do
      definition = {
        "slug" => "domain-scored", "kicker" => nil, "headline" => nil, "blurb" => nil, "start_label" => nil,
        "placement" => { "resolver_key" => nil },
        "questions" => [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "yes", "label" => "Yes", "hint" => nil, "weight" => 3 } ], "domain" => "governance" } ],
        "tiers" => {}, "levels" => {}, "warnings" => {},
        "bands" => [ { "ceiling" => 50, "name" => "Starter", "description" => "Just beginning." } ],
        "domains" => { "governance" => { "name" => "Governance", "gap_meaning" => "No owner.", "gap_cost" => "Drift." } }
      }
      diagnostic = Diagnostic.create!(slug: "domain-scored", kind: "scored", definition: definition)

      diagnostic.revert!
      diagnostic.compile!

      assert_equal definition, diagnostic.definition
    end

    test "upserts a diagnostic storing the definition keyed by its slug" do
      Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" })

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Diagnostic.find_by(slug: "seeded").definition)
    end

    test "upserting the same slug twice keeps a single diagnostic" do
      2.times { Diagnostic.upsert_definition({ "slug" => "seeded" }) }

      assert_equal 1, Diagnostic.where(slug: "seeded").count
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

    test "reports the overall captured percentage of the weight on offer" do
      diagnostic = Diagnostic.create!(slug: "scoring", kind: :scored, status: :draft)
      question = diagnostic.questions.create!(key: "q1", position: 1)
      question.options.create!(value: "full", weight: 4)
      question.options.create!(value: "partial", weight: 2)

      assert_equal 50, diagnostic.overall_percentage({ "q1" => "partial" })
    end

    test "the weight on offer is each question's heaviest option" do
      diagnostic = Diagnostic.create!(slug: "scoring", kind: :scored, status: :draft)
      light = diagnostic.questions.create!(key: "q1", position: 1)
      light.options.create!(value: "yes", weight: 4)
      heavy = diagnostic.questions.create!(key: "q2", position: 2)
      heavy.options.create!(value: "yes", weight: 6)

      assert_equal 40, diagnostic.overall_percentage({ "q1" => "yes" })
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
