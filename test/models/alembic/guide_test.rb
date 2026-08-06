require "test_helper"

module Alembic
  class GuideTest < ActiveSupport::TestCase
    Q = Guide::Question

    def guide(questions)
      Guide.new(slug: "t", questions: questions)
    end

    def domains(*keys)
      keys.to_h { |key| [ key, Guide::Domain.new(key: key, name: key.to_s, gap_meaning: nil, gap_cost: nil) ] }
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

    test "a score above every ceiling falls into the open-ended band" do
      banded = Guide.new(slug: "t", questions: [], bands: [ Guide::Band.new(ceiling: nil, name: "Top"), Guide::Band.new(ceiling: 10, name: "Low") ])

      assert_equal "Top", banded.band_for(40).name
    end

    test "a question exposes the domain it belongs to" do
      assert_equal :security, Q.new(id: :pii, text: "PII masked?", domain: :security).domain
    end

    test "a guide exposes a domain it was built with" do
      security = Guide::Domain.new(key: :security, name: "Security", gap_meaning: "Access is unreviewed.", gap_cost: "One leaked credential exposes everything.")
      domained = Guide.new(slug: "t", questions: [], domains: { security: security })

      assert_equal "Security", domained.domains[:security].name
    end

    test "the overall percentage is the captured weight over the weight on offer" do
      full = Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4)
      partial = Guide::Option.new(value: "partial", label: "Partial", hint: nil, weight: 2)
      scored = guide([ Q.new(id: :q1, text: "Q1", options: [ full, partial ]) ])

      assert_equal 50, scored.overall_percentage({ q1: "partial" })
    end

    test "a domain's percentage ignores the questions of other domains" do
      light = Q.new(id: :q1, text: "Q1", domain: :governance, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4) ])
      heavy = Q.new(id: :q2, text: "Q2", domain: :cash, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 6) ])
      scored = Guide.new(slug: "t", questions: [ light, heavy ], domains: domains(:governance, :cash))

      assert_equal 100, scored.domain_percentages({ q1: "full" })[:governance]
    end

    test "a band carries its description" do
      assert_equal "Just beginning.", Guide::Band.new(ceiling: 10, name: "Starter", description: "Just beginning.").description
    end
  end
end
