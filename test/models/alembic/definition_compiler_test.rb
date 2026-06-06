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
  end
end
