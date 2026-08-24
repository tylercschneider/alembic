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

    test "next question follows a transition past the question that is next in order" do
      target = Q.new(id: :c, text: "C")
      start = Q.new(id: :a, text: "A", transitions: [ Guide::Transition.new(to: :c) ])

      assert_equal target, guide([ start, Q.new(id: :b, text: "B"), target ]).next_question({ a: "x" })
    end

    test "next question ends the walk when a loop of answered questions repeats" do
      looped = [ Q.new(id: :a, text: "A", transitions: [ Guide::Transition.new(to: :b) ]),
                 Q.new(id: :b, text: "B", transitions: [ Guide::Transition.new(to: :a) ]) ]

      assert_nil guide(looped).next_question({ a: "x", b: "y" })
    end

    test "answers on path drop an answer the current path no longer reaches" do
      branching = [ Q.new(id: :path, text: "?", transitions: [ Guide::Transition.new(to: :right_q, condition: ->(answers) { answers[:path] == "right" }) ]),
                    Q.new(id: :left_q, text: "L"),
                    Q.new(id: :right_q, text: "R") ]

      assert_equal({ path: "left" }, guide(branching).answers_on_path({ path: "left", right_q: "y" }))
    end

    test "score ignores an answer the current path no longer reaches" do
      branching = [ Q.new(id: :path, text: "?", transitions: [ Guide::Transition.new(to: :right_q, condition: ->(answers) { answers[:path] == "right" }) ]),
                    Q.new(id: :left_q, text: "L"),
                    Q.new(id: :right_q, text: "R", options: [ Guide::Option.new(value: "y", label: "Y", hint: nil, weight: 10) ]) ]

      assert_equal 0, guide(branching).score({ path: "left", right_q: "y" })
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

    test "a domain with no weight on offer captures nothing rather than erroring" do
      weightless = Q.new(id: :q1, text: "Q1", domain: :governance, options: [ Guide::Option.new(value: "none", label: "None", hint: nil) ])
      scored = Guide.new(slug: "t", questions: [ weightless ], domains: domains(:governance))

      assert_equal 0, scored.domain_percentages({ q1: "none" })[:governance]
    end

    test "an unanswered question captures none of its weight" do
      answered = Q.new(id: :q1, text: "Q1", options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4) ])
      skipped = Q.new(id: :q2, text: "Q2", options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4) ])

      assert_equal 50, guide([ answered, skipped ]).overall_percentage({ q1: "full" })
    end

    test "an answer matching no option captures none of its weight" do
      offered = Q.new(id: :q1, text: "Q1", options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4) ])

      assert_equal 0, guide([ offered ]).overall_percentage({ q1: "stale" })
    end

    test "blind spots name as many of the weakest domains as asked for, weakest first" do
      strong = Q.new(id: :q1, text: "Q1", domain: :governance, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 4) ])
      empty = Q.new(id: :q2, text: "Q2", domain: :cash, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 6) ])
      partial = Q.new(id: :q3, text: "Q3", domain: :demand, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 8), Guide::Option.new(value: "half", label: "Half", hint: nil, weight: 4) ])
      scored = Guide.new(slug: "t", questions: [ strong, empty, partial ], domains: domains(:governance, :cash, :demand))

      assert_equal [ :cash, :demand ], scored.blind_spots({ q1: "full", q3: "half" }, count: 2)
    end

    test "a domain-scored result bands the overall percentage, not the weight sum" do
      question = Q.new(id: :q1, text: "Q1", domain: :governance, options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 200), Guide::Option.new(value: "partial", label: "Partial", hint: nil, weight: 60) ])
      bands = [ Guide::Band.new(ceiling: 50, name: "Flying blind"), Guide::Band.new(ceiling: nil, name: "Well instrumented") ]
      scored = Guide.new(slug: "t", questions: [ question ], domains: domains(:governance), bands: bands)

      assert_equal "Flying blind", scored.result_for({ q1: "partial" }).name
    end

    test "a result with no domains bands the raw score, not a percentage" do
      question = Q.new(id: :q1, text: "Q1", options: [ Guide::Option.new(value: "full", label: "Full", hint: nil, weight: 200), Guide::Option.new(value: "partial", label: "Partial", hint: nil, weight: 60) ])
      bands = [ Guide::Band.new(ceiling: 50, name: "Flying blind"), Guide::Band.new(ceiling: nil, name: "Well instrumented") ]
      scored = Guide.new(slug: "t", questions: [ question ], bands: bands)

      assert_equal "Well instrumented", scored.result_for({ q1: "partial" }).name
    end

    test "a band carries its description" do
      assert_equal "Just beginning.", Guide::Band.new(ceiling: 10, name: "Starter", description: "Just beginning.").description
    end
  end
end
