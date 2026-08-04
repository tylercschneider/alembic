require "test_helper"

module Alembic
  class OptionTest < ActiveSupport::TestCase
    test "orders a question's options by position" do
      diagnostic = Diagnostic.create!(slug: "option-ordering", kind: :scored, status: :draft)
      question = diagnostic.questions.create!(position: 1, key: "q")
      question.options.create!(position: 2, value: "b")
      question.options.create!(position: 1, value: "a")

      assert_equal [ "a", "b" ], question.options.ordered.map(&:value)
    end

    test "moving an option down places it after its neighbour" do
      question = Diagnostic.create!(slug: "option-move").questions.create!(position: 1, key: "q")
      first = question.options.create!(position: 1, value: "a")
      question.options.create!(position: 2, value: "b")

      first.move_down

      assert_equal [ "b", "a" ], question.options.ordered.map(&:value)
    end

    test "is invalid without a value" do
      option = Option.new(question: alembic_questions(:ladder_need), value: nil)

      assert_not option.valid?
    end
  end
end
