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

    test "builds a guide from its current definition" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "demo" })

      assert_equal "demo", diagnostic.to_guide.slug
    end

    test "stores guide copy and placement attributes" do
      diagnostic = Diagnostic.new(kicker: "k", headline: "h", blurb: "b", start_label: "s", resolver_key: "r")

      assert_equal [ "k", "h", "b", "s", "r" ], [ diagnostic.kicker, diagnostic.headline, diagnostic.blurb, diagnostic.start_label, diagnostic.resolver_key ]
    end

    test "recording a definition stores it as a version" do
      diagnostic = Diagnostic.create!(slug: "demo")

      diagnostic.record_definition({ "slug" => "demo" })

      assert_equal({ "slug" => "demo" }, diagnostic.definition_versions.last.definition)
    end

    test "recording a second definition takes the next version number" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "first" })

      diagnostic.record_definition({ "slug" => "second" })

      assert_equal 2, diagnostic.definition_versions.last.number
    end

    test "reports its current definition as the highest-numbered version" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "slug" => "first" })
      diagnostic.record_definition({ "slug" => "second" })

      assert_equal({ "slug" => "second" }, diagnostic.definition)
    end

    test "compiling records the compiled definition as a new version" do
      diagnostic = Diagnostic.create!(slug: "demo", headline: "Compiled")

      diagnostic.compile!

      assert_equal "Compiled", diagnostic.definition_versions.last.definition["headline"]
    end

    test "compiling a second time leaves the first version readable" do
      diagnostic = Diagnostic.create!(slug: "demo", headline: "First")
      diagnostic.compile!
      diagnostic.update!(headline: "Second")

      diagnostic.compile!

      assert_equal "First", diagnostic.definition_versions.find_by(number: 1).definition["headline"]
    end

    test "compiling writes the rows into the definition" do
      diagnostic = Diagnostic.create!(slug: "demo", headline: "Compiled")

      diagnostic.compile!

      assert_equal "Compiled", diagnostic.definition["headline"]
    end

    test "reverting decompiles the definition into rows" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition({ "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      diagnostic.revert!

      assert_equal [ "need" ], diagnostic.questions.ordered.map(&:key)
    end

    test "reverting then compiling round-trips the bundled definition" do
      definition = Alembic.bundled_definition("stats-system-ladder")
      diagnostic = alembic_diagnostics(:stats_ladder)
      diagnostic.record_definition(definition)

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
      diagnostic = Diagnostic.create!(slug: "domain-scored", kind: "scored")
      diagnostic.record_definition(definition)

      diagnostic.revert!
      diagnostic.compile!

      assert_equal definition, diagnostic.definition
    end

    test "upserting records the imported definition as a version" do
      Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" })

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Diagnostic.find_by(slug: "seeded").definition_versions.last.definition)
    end

    test "upserting an unchanged definition records no new version" do
      2.times { Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" }) }

      assert_equal 1, Diagnostic.find_by(slug: "seeded").definition_versions.count
    end

    test "upserts a diagnostic storing the definition keyed by its slug" do
      Diagnostic.upsert_definition({ "slug" => "seeded", "headline" => "Hi" })

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Diagnostic.find_by(slug: "seeded").definition)
    end

    test "upserting the same slug twice keeps a single diagnostic" do
      2.times { Diagnostic.upsert_definition({ "slug" => "seeded" }) }

      assert_equal 1, Diagnostic.where(slug: "seeded").count
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
