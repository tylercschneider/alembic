require "test_helper"

module Alembic
  class StepsBuilderTest < ActionDispatch::IntegrationTest
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
