require "test_helper"

module Alembic
  module Flow
    class DigestTest < ActiveSupport::TestCase
      def registry
        @registry ||= Registry.new.tap do |built|
          built.register(StepType.define(:ask) { setting :text, type: :string; awaits_input })
          built.register(StepType.define(:branch) do
            setting :answer, type: :string
            outputs :yes, :no
            requires { |node| [ node.config["answer"] ].compact }
            route { |node, state| state[node.config["answer"]] == "yes" ? :yes : :no }
          end)
        end
      end

      def digest(document)
        Digest.new(Document.new(document), registry: registry)
      end

      def branching
        { "entry" => "first",
          "nodes" => [ { "id" => "first", "type" => "ask", "text" => "First?" },
                       { "id" => "gate", "type" => "branch", "answer" => "first" },
                       { "id" => "yes_step", "type" => "ask" },
                       { "id" => "no_step", "type" => "ask" },
                       { "id" => "last", "type" => "ask" } ],
          "edges" => [ { "from" => "first", "to" => "gate" },
                       { "from" => "gate", "to" => "yes_step", "on" => "yes" },
                       { "from" => "gate", "to" => "no_step", "on" => "no" },
                       { "from" => "yes_step", "to" => "last" },
                       { "from" => "no_step", "to" => "last" } ] }
      end

      test "reports the step a flow begins at" do
        assert_equal "first", digest(branching).entry.id
      end

      test "finds a step by its id" do
        assert_equal "gate", digest(branching).step("gate").id
      end

      test "reports what a step requires" do
        assert_equal [ "first" ], digest(branching).requirements("gate")
      end

      test "reports the steps a step's configuration refers to" do
        referring = branching.merge("nodes" => branching["nodes"] + [ { "id" => "recap", "type" => "ask", "text" => "You said {{first}}" } ])

        assert_equal [ "first" ], digest(referring).references("recap")
      end

      test "reports nothing required by a step that declares none" do
        assert_empty digest(branching).requirements("first")
      end

      test "the first step is the one a flow reaches with nothing recorded" do
        assert_equal "first", digest(branching).next_step({}).id
      end

      test "a step that awaits nothing is passed straight through" do
        assert_equal "yes_step", digest(branching).next_step({ "first" => "yes" }).id
      end

      test "a branching step sends the flow down the path its state selects" do
        assert_equal "no_step", digest(branching).next_step({ "first" => "no" }).id
      end

      test "the flow reaches the step both branches share" do
        assert_equal "last", digest(branching).next_step({ "first" => "no", "no_step" => "x" }).id
      end

      test "a finished flow reaches no further step" do
        assert_nil digest(branching).next_step({ "first" => "no", "no_step" => "x", "last" => "y" })
      end

      test "state on the path leaves out what an abandoned branch recorded" do
        wandered = { "first" => "no", "yes_step" => "stale", "no_step" => "x" }

        assert_equal({ "first" => "no", "no_step" => "x" }, digest(branching).state_on_path(wandered))
      end

      test "traversal ends on a flow whose edges form a cycle" do
        looping = { "entry" => "a",
                    "nodes" => [ { "id" => "a", "type" => "branch", "answer" => "nothing" }, { "id" => "b", "type" => "branch", "answer" => "nothing" } ],
                    "edges" => [ { "from" => "a", "to" => "b", "on" => "no" }, { "from" => "b", "to" => "a", "on" => "no" } ] }

        assert_nil digest(looping).next_step({})
      end
    end
  end
end
