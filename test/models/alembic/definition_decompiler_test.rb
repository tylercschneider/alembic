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
  end
end
