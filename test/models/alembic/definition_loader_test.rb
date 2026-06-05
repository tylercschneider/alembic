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
  end
end
