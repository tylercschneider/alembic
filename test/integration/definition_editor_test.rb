require "test_helper"

module Alembic
  class DefinitionEditorTest < ActionDispatch::IntegrationTest
    test "the definition editor shows the current definition" do
      diagnostic = Diagnostic.create!(slug: "doc")
      diagnostic.record_definition("slug" => "doc", "questions" => [ { "id" => "need", "text" => "Need?" } ])

      get alembic.edit_manage_diagnostic_definition_path(diagnostic)

      assert_select "textarea", text: /"id": "need"/
    end
  end
end
