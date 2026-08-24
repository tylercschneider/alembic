require "test_helper"

module Alembic
  class TransitionTest < ActiveSupport::TestCase
    test "a transition links one question to another" do
      diagnostic = Diagnostic.create!(slug: "flow")
      from = diagnostic.questions.create!(key: "a", position: 1)
      to = diagnostic.questions.create!(key: "b", position: 2)

      transition = Transition.create!(from_question: from, to_question: to)

      assert_equal to, transition.to_question
    end
  end
end
