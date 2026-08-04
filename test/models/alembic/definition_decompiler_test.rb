require "test_helper"

module Alembic
  class DefinitionDecompilerTest < ActiveSupport::TestCase
    test "writes the copy onto the diagnostic" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "headline" => "Hi", "kicker" => "K", "blurb" => "B", "start_label" => "Go" })

      assert_equal [ "Hi", "K", "B", "Go" ], [ diagnostic.headline, diagnostic.kicker, diagnostic.blurb, diagnostic.start_label ]
    end

    test "writes the placement resolver key onto the diagnostic" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "placement" => { "resolver_key" => "stats_ladder" } })

      assert_equal "stats_ladder", diagnostic.resolver_key
    end

    test "builds question rows keyed and ordered from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "questions" => [ { "id" => "need", "text" => "Need?" }, { "id" => "read", "text" => "Read?" } ] })

      assert_equal [ "need", "read" ], diagnostic.questions.ordered.map(&:key)
    end

    test "builds option rows under their question from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "questions" => [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "now", "label" => "Now", "hint" => "h" } ] } ] })

      option = diagnostic.questions.first.options.first
      assert_equal [ "now", "Now", "h" ], [ option.value, option.label, option.hint ]
    end

    test "builds an option row carrying its weight from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "questions" => [ { "id" => "need", "text" => "Need?", "options" => [ { "value" => "now", "weight" => 3 } ] } ] })

      assert_equal 3, diagnostic.questions.first.options.first.weight
    end

    test "builds a condition gating a question on another question's answer" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "questions" => [
        { "id" => "need", "text" => "Need?", "options" => [ { "value" => "rates" }, { "value" => "now" } ] },
        { "id" => "loss", "text" => "Loss?", "condition" => { "answer" => "need", "equals" => "rates" } }
      ] })

      assert_not diagnostic.questions.find_by(key: "loss").applies?({ "need" => "now" })
    end

    test "builds tier and level node rows from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "tiers" => { "1" => { "name" => "Live query" } }, "levels" => { "l3" => { "name" => "Outbox" } } })

      assert_equal [ [ "tier", "1" ], [ "level", "l3" ] ], diagnostic.nodes.map { |node| [ node.kind, node.key ] }
    end

    test "builds build step rows under their node from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "tiers" => { "1" => { "name" => "Live query", "build_steps" => [ { "title" => "Index", "code" => "add_index" } ] } } })

      step = diagnostic.nodes.first.build_steps.first
      assert_equal [ "Index", "add_index" ], [ step.title, step.code ]
    end

    test "builds warning rows from the definition" do
      diagnostic = Diagnostic.create!(slug: "decompiled")

      DefinitionDecompiler.new(diagnostic).load({ "warnings" => { "money_pairing" => "Good pairing." } })

      assert_equal "Good pairing.", diagnostic.warnings.find_by(key: "money_pairing").text
    end

    test "reloading replaces children instead of duplicating them" do
      diagnostic = Diagnostic.create!(slug: "decompiled")
      definition = { "questions" => [ { "id" => "need", "text" => "Need?" } ], "warnings" => { "w" => "x" }, "tiers" => { "1" => { "name" => "T" } } }

      2.times { DefinitionDecompiler.new(diagnostic).load(definition) }

      assert_equal [ 1, 1, 1 ], [ diagnostic.questions.count, diagnostic.warnings.count, diagnostic.nodes.count ]
    end

    test "decompiles the bundled stats-ladder definition into rows" do
      diagnostic = Diagnostic.create!(slug: "bundled-ladder")

      DefinitionDecompiler.new(diagnostic).load(Alembic.bundled_definition("stats-system-ladder"))

      assert_equal "Event log + rollups", diagnostic.nodes.find_by(kind: "tier", key: "4").name
    end
  end
end
