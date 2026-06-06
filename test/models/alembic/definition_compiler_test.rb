require "test_helper"

module Alembic
  class DefinitionCompilerTest < ActiveSupport::TestCase
    test "compiles the slug and copy" do
      diagnostic = Diagnostic.create!(slug: "demo", kicker: "K", headline: "H", blurb: "B", start_label: "Go")

      assert_equal({ "slug" => "demo", "kicker" => "K", "headline" => "H", "blurb" => "B", "start_label" => "Go" },
        DefinitionCompiler.new(diagnostic).to_definition.slice("slug", "kicker", "headline", "blurb", "start_label"))
    end

    test "compiles the placement resolver key" do
      diagnostic = Diagnostic.create!(slug: "demo", resolver_key: "stats_ladder")

      assert_equal({ "resolver_key" => "stats_ladder" }, DefinitionCompiler.new(diagnostic).to_definition["placement"])
    end

    test "compiles questions with their options" do
      diagnostic = Diagnostic.create!(slug: "demo")
      question = diagnostic.questions.create!(key: "need", text: "Need?", position: 1)
      question.options.create!(value: "now", label: "Now", hint: "h", position: 1)

      assert_equal [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "now", "label" => "Now", "hint" => "h" } ] } ],
        DefinitionCompiler.new(diagnostic).to_definition["questions"]
    end

    test "compiles a single-option condition as equals" do
      diagnostic = Diagnostic.create!(slug: "demo")
      DefinitionDecompiler.new(diagnostic).load({ "questions" => [
        { "id" => "need", "text" => "Need?", "options" => [ { "value" => "rates" } ] },
        { "id" => "loss", "text" => "Loss?", "condition" => { "answer" => "need", "equals" => "rates" } }
      ] })

      loss = DefinitionCompiler.new(diagnostic).to_definition["questions"].find { |q| q["id"] == "loss" }
      assert_equal({ "answer" => "need", "equals" => "rates" }, loss["condition"])
    end

    test "compiles a multi-option condition as in" do
      diagnostic = Diagnostic.create!(slug: "demo")
      DefinitionDecompiler.new(diagnostic).load({ "questions" => [
        { "id" => "need", "text" => "Need?", "options" => [ { "value" => "rates" }, { "value" => "audit" } ] },
        { "id" => "origin", "text" => "Origin?", "condition" => { "answer" => "need", "in" => [ "rates", "audit" ] } }
      ] })

      origin = DefinitionCompiler.new(diagnostic).to_definition["questions"].find { |q| q["id"] == "origin" }
      assert_equal({ "answer" => "need", "in" => [ "rates", "audit" ] }, origin["condition"])
    end

    test "compiles tier nodes keyed by their key with present text" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.nodes.create!(kind: "tier", key: "1", position: 1, name: "Live query", captures: "now")

      assert_equal({ "1" => { "name" => "Live query", "captures" => "now" } }, DefinitionCompiler.new(diagnostic).to_definition["tiers"])
    end

    test "compiles a node's build steps" do
      diagnostic = Diagnostic.create!(slug: "demo")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", position: 1, name: "Live query")
      node.build_steps.create!(title: "Index", code: "add_index", position: 1)

      assert_equal [ { "title" => "Index", "code" => "add_index" } ], DefinitionCompiler.new(diagnostic).to_definition["tiers"]["1"]["build_steps"]
    end

    test "compiles warnings keyed by key" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.warnings.create!(key: "money_pairing", text: "Good pairing.")

      assert_equal({ "money_pairing" => "Good pairing." }, DefinitionCompiler.new(diagnostic).to_definition["warnings"])
    end

    test "round-trips the bundled stats-ladder definition through rows" do
      definition = Alembic.bundled_definition("stats-system-ladder")
      diagnostic = alembic_diagnostics(:stats_ladder)

      DefinitionDecompiler.new(diagnostic).load(definition)

      assert_equal definition, DefinitionCompiler.new(diagnostic).to_definition
    end
  end
end
