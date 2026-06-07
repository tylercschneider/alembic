require "test_helper"

module Alembic
  class ConditionsBuilderTest < ActionDispatch::IntegrationTest
    test "saving a condition gates the question on the selected options" do
      diagnostic = Diagnostic.create!(slug: "cond")
      need = diagnostic.questions.create!(key: "need", position: 1)
      rates = need.options.create!(value: "rates", position: 1)
      loss = diagnostic.questions.create!(key: "loss", position: 2)

      patch alembic.manage_diagnostic_question_condition_path(diagnostic, loss), params: { condition: { option_ids: [ rates.id ] } }

      assert_not loss.reload.applies?({ "need" => "now" })
    end
  end
end
