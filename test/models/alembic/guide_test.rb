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

    test "scoring sums the weights of the answered options" do
      option = Guide::Option.new(value: "yes", label: "Yes", hint: nil, weight: 3)
      scored = guide([ Q.new(id: :need, text: "Need?", options: [ option ]) ])

      assert_equal 3, scored.score({ need: "yes" })
    end

    test "a score falls into the first band whose ceiling it is under" do
      banded = Guide.new(slug: "t", questions: [], bands: [ Guide::Band.new(ceiling: 10, name: "Low"), Guide::Band.new(ceiling: 20, name: "High") ])

      assert_equal "Low", banded.band_for(4).name
    end

    test "a band carries its description" do
      assert_equal "Just beginning.", Guide::Band.new(ceiling: 10, name: "Starter", description: "Just beginning.").description
    end
  end
end
