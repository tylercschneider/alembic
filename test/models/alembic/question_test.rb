require "test_helper"

module Alembic
  class QuestionTest < ActiveSupport::TestCase
    test "orders a diagnostic's questions by position" do
      diagnostic = Diagnostic.create!(slug: "ordering-test", kind: :scored, status: :draft)
      diagnostic.questions.create!(position: 2, key: "b", text: "B")
      diagnostic.questions.create!(position: 1, key: "a", text: "A")

      assert_equal [ "a", "b" ], diagnostic.questions.ordered.map(&:key)
    end

    test "moving a question down places it after its neighbour" do
      diagnostic = Diagnostic.create!(slug: "move-down")
      first = diagnostic.questions.create!(position: 1, key: "a")
      diagnostic.questions.create!(position: 2, key: "b")

      first.move_down

      assert_equal [ "b", "a" ], diagnostic.questions.ordered.map(&:key)
    end

    test "is invalid without a key" do
      question = Question.new(diagnostic: alembic_diagnostics(:stats_ladder), key: nil)

      assert_not question.valid?
    end

    test "a question with no conditions applies to any answers" do
      assert alembic_questions(:ladder_need).applies?({})
    end

    test "a question with an unmet condition does not apply" do
      assert_not alembic_questions(:ladder_read).applies?({ "need" => "rates" })
    end

    test "updates a nested option through the question" do
      question = Diagnostic.create!(slug: "nested").questions.create!(key: "q", position: 1)
      option = question.options.create!(value: "old", position: 1)

      question.update!(options_attributes: [ { id: option.id, value: "new" } ])

      assert_equal "new", option.reload.value
    end

    test "destroying a question destroys conditions in other questions that test it" do
      diagnostic = Diagnostic.create!(slug: "testedby")
      need = diagnostic.questions.create!(key: "need", position: 1)
      rates = need.options.create!(value: "rates", position: 1)
      loss = diagnostic.questions.create!(key: "loss", position: 2)
      loss.conditions.create!(tested_question: need, options: [ rates ])

      assert_difference -> { Condition.count }, -1 do
        need.destroy!
      end
    end
  end
end
