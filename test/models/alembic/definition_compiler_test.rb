require "test_helper"

module Alembic
  class DefinitionCompilerTest < ActiveSupport::TestCase
    test "compiles the slug and copy" do
      diagnostic = Diagnostic.create!(slug: "demo", kicker: "K", headline: "H", blurb: "B", start_label: "Go")

      assert_equal({ "slug" => "demo", "kicker" => "K", "headline" => "H", "blurb" => "B", "start_label" => "Go" },
        DefinitionCompiler.new(diagnostic).to_definition.slice("slug", "kicker", "headline", "blurb", "start_label"))
    end
  end
end
