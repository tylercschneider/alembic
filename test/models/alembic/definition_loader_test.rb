require "test_helper"

module Alembic
  class DefinitionLoaderTest < ActiveSupport::TestCase
    test "builds a guide carrying the definition's slug" do
      loader = DefinitionLoader.new({ "slug" => "demo" })

      assert_equal "demo", loader.build.slug
    end

    test "builds a guide carrying the definition's headline" do
      loader = DefinitionLoader.new({ "headline" => "Where to?" })

      assert_equal "Where to?", loader.build.headline
    end

    test "builds a guide carrying the definition's kicker" do
      loader = DefinitionLoader.new({ "kicker" => "Diagnose · Place" })

      assert_equal "Diagnose · Place", loader.build.kicker
    end

    test "builds a guide carrying the definition's blurb" do
      loader = DefinitionLoader.new({ "blurb" => "Answer a few questions." })

      assert_equal "Answer a few questions.", loader.build.blurb
    end

    test "builds a guide carrying the definition's start label" do
      loader = DefinitionLoader.new({ "start_label" => "Start the quiz →" })

      assert_equal "Start the quiz →", loader.build.start_label
    end

    test "builds a question carrying its id as a symbol" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      assert_equal :need, loader.build.questions.first.id
    end

    test "builds a question's option carrying its value" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "now" } ] } ] })

      assert_equal "now", loader.build.questions.first.options.first.value
    end

    test "builds a question's option carrying its weight" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "now", "weight" => 3 } ] } ] })

      assert_equal 3, loader.build.questions.first.options.first.weight
    end

    test "builds a question's transition carrying its target" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "?", "transitions" => [ { "to" => "loss" } ] } ] })

      assert_equal :loss, loader.build.questions.first.transitions.first.to
    end

    test "a transition is unavailable when its condition is unmet" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "?", "transitions" => [ { "to" => "loss", "condition" => { "answer" => "need", "equals" => "rates" } } ] } ] })

      assert_not loader.build.questions.first.transitions.first.available?({ need: "now" })
    end

    test "an equals condition leaves a question inapplicable when the answer differs" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "loss", "text" => "?", "condition" => { "answer" => "need", "equals" => "rates" } } ] })

      assert_not loader.build.questions.first.applies?({ need: "now" })
    end

    test "an in condition leaves a question applicable when the answer is in the set" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "origin", "text" => "?", "condition" => { "answer" => "need", "in" => [ "rates", "audit" ] } } ] })

      assert loader.build.questions.first.applies?({ need: "audit" })
    end

    test "builds a warning carrying its text keyed by symbol" do
      loader = DefinitionLoader.new({ "warnings" => { "insight_pairing" => "Insight-grade." } })

      assert_equal "Insight-grade.", loader.build.warning_text(:insight_pairing)
    end

    test "builds a tier node keyed by integer carrying its name" do
      loader = DefinitionLoader.new({ "tiers" => { "1" => { "name" => "Live query" } } })

      assert_equal "Live query", loader.build.tier(1).name
    end

    test "builds a level node keyed by symbol carrying its name" do
      loader = DefinitionLoader.new({ "levels" => { "l3" => { "name" => "Outbox" } } })

      assert_equal "Outbox", loader.build.level(:l3).name
    end

    test "a node carries its optional descriptive text" do
      loader = DefinitionLoader.new({ "tiers" => { "1" => { "name" => "Live query", "captures" => "The current value." } } })

      assert_equal "The current value.", loader.build.tier(1).captures
    end

    test "a node carries its build steps with code" do
      loader = DefinitionLoader.new({ "tiers" => { "1" => { "name" => "Live query", "build_steps" => [ { "title" => "Index", "code" => "add_index :contacts, :status" } ] } } })

      assert_equal "add_index :contacts, :status", loader.build.tier(1).build_steps.first.code
    end

    test "builds a band carrying its name" do
      loader = DefinitionLoader.new({ "bands" => [ { "ceiling" => 10, "name" => "Starter", "description" => "Just beginning." } ] })

      assert_equal "Starter", loader.build.bands.first.name
    end

    test "builds a question carrying its domain key as a symbol" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "pii", "text" => "PII masked?", "domain" => "security" } ] })

      assert_equal :security, loader.build.questions.first.domain
    end

    test "builds a question with no domain when the definition names none" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      assert_nil loader.build.questions.first.domain
    end

    test "builds a domain keyed by symbol carrying its name" do
      loader = DefinitionLoader.new({ "domains" => { "security" => { "name" => "Security" } } })

      assert_equal "Security", loader.build.domains[:security].name
    end

    test "builds a domain carrying what a gap in it means" do
      loader = DefinitionLoader.new({ "domains" => { "security" => { "gap_meaning" => "Access is unreviewed." } } })

      assert_equal "Access is unreviewed.", loader.build.domains[:security].gap_meaning
    end

    test "builds a domain carrying what a gap in it costs" do
      loader = DefinitionLoader.new({ "domains" => { "security" => { "gap_cost" => "A leaked credential exposes everything." } } })

      assert_equal "A leaked credential exposes everything.", loader.build.domains[:security].gap_cost
    end

    test "builds no domains from a definition without a domains section" do
      loader = DefinitionLoader.new({ "slug" => "demo" })

      assert_empty loader.build.domains
    end

    test "a compiled question's domain resolves to a domain the guide carries" do
      diagnostic = Diagnostic.create!(slug: "demo")
      security = diagnostic.domains.create!(key: "security", name: "Security", gap_meaning: "Access is unreviewed.", gap_cost: "A leaked credential exposes everything.", position: 1)
      diagnostic.questions.create!(key: "pii", text: "PII masked?", position: 1, domain: security)

      guide = DefinitionLoader.new(DefinitionCompiler.new(diagnostic).to_definition).build

      assert_equal "Security", guide.domains[guide.questions.first.domain].name
    end

    test "selects the resolver named by the definition's placement key" do
      loader = DefinitionLoader.new({ "placement" => { "resolver_key" => "stats_ladder" } })

      assert_instance_of StatsLadderPlacement, loader.build.resolver
    end
  end
end
