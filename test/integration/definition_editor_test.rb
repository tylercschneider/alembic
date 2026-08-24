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

    test "a branching definition saved in the builder runs in the stepper" do
      diagnostic = Diagnostic.create!(slug: "flow")
      diagnostic.record_definition("slug" => "flow")

      patch alembic.manage_diagnostic_definition_path(diagnostic), params: { definition: {
        "slug" => "flow",
        "questions" => [
          { "id" => "path", "text" => "Which path?", "options" => [ { "value" => "left" }, { "value" => "right" } ],
            "transitions" => [ { "to" => "right_q", "condition" => { "answer" => "path", "equals" => "right" } } ] },
          { "id" => "left_q", "text" => "Left question", "options" => [ { "value" => "x" } ] },
          { "id" => "right_q", "text" => "Right question", "options" => [ { "value" => "y" } ] }
        ]
      }.to_json }

      get alembic.diagnostic_step_path("flow"), params: { answers: { path: "right" } }

      assert_select "legend", text: /Right question/
    end

    test "the definition editor shows the current definition" do
      diagnostic = Diagnostic.create!(slug: "doc")
      diagnostic.record_definition("slug" => "doc", "questions" => [ { "id" => "need", "text" => "Need?" } ])

      get alembic.edit_manage_diagnostic_definition_path(diagnostic)

      assert_select "textarea", text: /"id": "need"/
    end
  end
end
