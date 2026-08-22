require "test_helper"

module Alembic
  class DefinitionVersionTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_equal diagnostic, version.diagnostic
    end

    test "is invalid when the diagnostic already has that version number" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      duplicate = diagnostic.definition_versions.build(number: 1, definition: { "slug" => "demo" })

      assert_not duplicate.valid?
    end
  end
end
