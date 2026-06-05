require "test_helper"

module Alembic
  class QuestionTest < ActiveSupport::TestCase
    test "orders a diagnostic's questions by position" do
      diagnostic = Diagnostic.create!(slug: "ordering-test", kind: :scored, status: :draft)
      diagnostic.questions.create!(position: 2, key: "b", text: "B")
      diagnostic.questions.create!(position: 1, key: "a", text: "A")

      assert_equal [ "a", "b" ], diagnostic.questions.ordered.map(&:key)
    end

    test "is invalid without a key" do
      question = Question.new(diagnostic: alembic_diagnostics(:stats_ladder), key: nil)

      assert_not question.valid?
    end

    test "a question with no conditions applies to any answers" do
      assert alembic_questions(:ladder_need).applies?({})
    end
  end
end
