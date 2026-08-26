require "test_helper"

module Alembic
  class RunnerTest < ActiveSupport::TestCase
    def branching
      { "slug" => "r", "entry" => "first",
        "nodes" => [ { "id" => "first", "type" => "question", "text" => "Budget?", "options" => [ "low", "high" ] },
                     { "id" => "gate", "type" => "condition", "step" => "first", "answer" => "high" },
                     { "id" => "posh", "type" => "question", "text" => "Which premium tier?" },
                     { "id" => "plain", "type" => "question", "text" => "Which basic tier?" } ],
        "edges" => [ { "from" => "first", "to" => "gate" },
                     { "from" => "gate", "to" => "posh", "on" => true },
                     { "from" => "gate", "to" => "plain", "on" => false } ] }
    end

    def runner(definition = branching)
      Runner.new(definition)
    end

    test "asks the step a flow begins at" do
      assert_equal "Budget?", runner.next_question({}).text
    end

    test "identifies the step it is asking" do
      assert_equal :first, runner.next_question({}).id
    end

    test "offers a choice for each option a step lists" do
      assert_equal [ "low", "high" ], runner.next_question({}).choices.map(&:value)
    end

    test "labels a choice given as a plain value by that value" do
      assert_equal "low", runner.next_question({}).choices.first.label
    end

    test "labels a choice given as a record by its own label" do
      described = branching.merge("nodes" => branching["nodes"].map do |node|
        node["id"] == "first" ? node.merge("options" => [ { "value" => "low", "label" => "Not much" } ]) : node
      end)

      assert_equal "Not much", runner(described).next_question({}).choices.first.label
    end

    test "passes through a condition to the branch the answers select" do
      assert_equal :posh, runner.next_question({ first: "high" }).id
    end

    test "passes through a condition to the other branch" do
      assert_equal :plain, runner.next_question({ first: "low" }).id
    end

    test "asks nothing once the flow has run out of steps" do
      assert_nil runner.next_question({ first: "low", plain: "x" })
    end

    test "leaves out an answer stranded on a branch no longer taken" do
      wandered = { first: "low", posh: "stale", plain: "x" }

      assert_equal({ first: "low", plain: "x" }, runner.answers_on_path(wandered))
    end
  end
end
