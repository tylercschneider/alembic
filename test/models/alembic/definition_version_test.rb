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

    test "is valid when a different diagnostic already has that version number" do
      Diagnostic.create!(slug: "taken").definition_versions.create!(number: 1, definition: { "slug" => "taken" })
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.definition_versions.build(number: 1, definition: { "slug" => "demo" })

      assert version.valid?
    end

    test "refuses to be updated once persisted" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(definition: { "slug" => "rewritten" }) }
    end

    test "a version that has been created but never published is a draft" do
      diagnostic = Diagnostic.create!(slug: "demo")

      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_predicate version, :draft?
    end

    test "its status may change" do
      version = Diagnostic.create!(slug: "demo").definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      version.update!(status: :live)

      assert_predicate version.reload, :live?
    end
  end
end
