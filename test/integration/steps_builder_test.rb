require "test_helper"

module Alembic
  class StepsBuilderTest < ActionDispatch::IntegrationTest
    test "reordering the steps saves a new version in the new order" do
      diagnostic = Diagnostic.create!(slug: "steps")
      diagnostic.record_definition("slug" => "steps", "questions" => [ { "id" => "a" }, { "id" => "b" } ])

      patch alembic.reorder_manage_diagnostic_steps_path(diagnostic), params: { ids: [ "b", "a" ] }

      assert_equal [ "b", "a" ], diagnostic.reload.definition["questions"].map { |question| question["id"] }
    end

    test "the steps screen loads the reorder script" do
      diagnostic = Diagnostic.create!(slug: "steps")
      diagnostic.record_definition("slug" => "steps", "questions" => [ { "id" => "a" } ])

      get alembic.manage_diagnostic_steps_path(diagnostic)

      assert_select "script[src*=?]", "step_reorder"
    end

    test "the steps screen lists the document's questions in order" do
      diagnostic = Diagnostic.create!(slug: "steps")
      diagnostic.record_definition("slug" => "steps", "questions" => [
        { "id" => "a", "text" => "First step" }, { "id" => "b", "text" => "Second step" }
      ])

      get alembic.manage_diagnostic_steps_path(diagnostic)

      assert_select "li[data-step-id=?]", "a"
    end
  end
end
