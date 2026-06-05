require "test_helper"

module Alembic
  class GuideTest < ActiveSupport::TestCase
    Q = Guide::Question

    def guide(questions)
      Guide.new(slug: "t", questions: questions)
    end

    test "next question is the first one when nothing is answered" do
      first = Q.new(id: :a, text: "A")

      assert_equal first, guide([ first, Q.new(id: :b, text: "B") ]).next_question({})
    end

    test "next question skips a question that is already answered" do
      second = Q.new(id: :b, text: "B")

      assert_equal second, guide([ Q.new(id: :a, text: "A"), second ]).next_question({ a: "x" })
    end

    test "next question skips a question whose condition is unmet" do
      gated = Q.new(id: :b, text: "B", condition: ->(answers) { answers[:a] == "yes" })
      fallback = Q.new(id: :c, text: "C")

      assert_equal fallback, guide([ gated, fallback ]).next_question({ a: "no" })
    end

    test "complete when every applicable question is answered" do
      assert guide([ Q.new(id: :a, text: "A") ]).complete?({ a: "x" })
    end

    test "place delegates to the configured resolver" do
      resolver = ->(answers) { "placed:#{answers[:need]}" }
      placing = Guide.new(slug: "t", questions: [], resolver: resolver)

      assert_equal "placed:now", placing.place({ need: "now" })
    end

    test "a build step carries its code" do
      assert_equal "Job.count", Guide::BuildStep.new(title: "Count", code: "Job.count").code
    end

    test "applicable questions exclude one whose condition is unmet" do
      gated = Q.new(id: :b, text: "B", condition: ->(answers) { answers[:a] == "yes" })

      assert_equal [ :a ], guide([ Q.new(id: :a, text: "A"), gated ]).applicable_questions({}).map(&:id)
    end
  end
end
