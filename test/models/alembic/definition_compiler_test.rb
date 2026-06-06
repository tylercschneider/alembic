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
  end
end
