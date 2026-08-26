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
        "slug" => "flow", "entry" => "path",
        "nodes" => [
          { "id" => "path", "type" => "question", "text" => "Which path?", "options" => [ "left", "right" ] },
          { "id" => "gate", "type" => "condition", "step" => "path", "answer" => "right" },
          { "id" => "left_q", "type" => "question", "text" => "Left question", "options" => [ "x" ] },
          { "id" => "right_q", "type" => "question", "text" => "Right question", "options" => [ "y" ] }
        ],
        "edges" => [
          { "from" => "path", "to" => "gate" },
          { "from" => "gate", "to" => "right_q", "on" => "yes" },
          { "from" => "gate", "to" => "left_q", "on" => "no" }
        ]
      }.to_json }

      diagnostic.reload.publish

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
