require "test_helper"

module Alembic
  class DefinitionEditorTest < ActionDispatch::IntegrationTest
    test "saving the definition records a new version" do
      diagnostic = Diagnostic.create!(slug: "doc")
      diagnostic.record_definition("slug" => "doc")

      assert_difference -> { diagnostic.definition_versions.count } do
        patch alembic.manage_diagnostic_definition_path(diagnostic),
          params: { definition: { "slug" => "doc", "questions" => [ { "id" => "need" } ] }.to_json }
      end
    end

    test "the definition editor shows the current definition" do
      diagnostic = Diagnostic.create!(slug: "doc")
      diagnostic.record_definition("slug" => "doc", "questions" => [ { "id" => "need", "text" => "Need?" } ])

      get alembic.edit_manage_diagnostic_definition_path(diagnostic)

      assert_select "textarea", text: /"id": "need"/
    end
  end
end
