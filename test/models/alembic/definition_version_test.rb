require "test_helper"

module Alembic
  class DefinitionVersionTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_equal diagnostic, version.diagnostic
    end
  end
end
