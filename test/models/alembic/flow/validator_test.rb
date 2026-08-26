require "test_helper"

module Alembic
  module Flow
    class ValidatorTest < ActiveSupport::TestCase
      def violations(document, registry = Flow.registry)
        Validator.new(Document.new(document), registry: registry).violations
      end

      def needy_registry
        Registry.new.tap do |registry|
          registry.register(StepType.define(:needy) { requires { |node| [ node.config["needs"] ].compact } })
          registry.register(StepType.define(:plain) { })
        end
      end

      def needy_document(edges)
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "r", "type" => "plain" },
                       { "id" => "x", "type" => "needy", "needs" => "r" } ],
          "edges" => edges }
      end

      test "accepts a requirement that lies on the only path to the step" do
        document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "r", "to" => "x" } ])

        assert_empty violations(document, needy_registry)
      end

      test "reports a requirement that lies on only one of two paths to the step" do
        document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "r", "to" => "x" }, { "from" => "a", "to" => "x" } ])

        assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
      end

      test "identifies the step and the requirement that is unmet" do
        document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "a", "to" => "x" } ])
        violation = violations(document, needy_registry).first

        assert_equal [ "x", "r" ], [ violation.node, violation.detail ]
      end

      test "reports a requirement naming a step the document does not carry" do
        document = { "entry" => "a",
                     "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "x", "type" => "needy", "needs" => "ghost" } ],
                     "edges" => [ { "from" => "a", "to" => "x" } ] }

        assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
      end

      test "never reports a step that requires nothing" do
        document = { "entry" => "a",
                     "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "x", "type" => "plain" } ],
                     "edges" => [ { "from" => "a", "to" => "x" } ] }

        assert_empty violations(document, needy_registry)
      end

      test "checks requirements on a document whose edges form a cycle" do
        document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "r", "to" => "x" }, { "from" => "x", "to" => "r" } ])

        assert_empty violations(document, needy_registry)
      end

      test "reports a requirement that lies on no path to the step" do
        document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "a", "to" => "x" } ])

        assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
      end

      test "reports nothing for a whole document with none of these problems" do
        document = {
          "entry" => "ask", "nodes" => [ { "id" => "ask" }, { "id" => "branch" }, { "id" => "yes_step" }, { "id" => "no_step" } ],
          "edges" => [ { "from" => "ask", "to" => "branch" },
                       { "from" => "branch", "to" => "yes_step", "on" => "yes" },
                       { "from" => "branch", "to" => "no_step", "on" => "no" } ]
        }

        assert_empty violations(document)
      end

      test "reports a node that cannot be reached from the entry" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "stranded" } ], "edges" => [] }

        assert_equal [ :unreachable ], violations(document).map(&:problem)
      end

      test "reaches a node by following an edge from the entry" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ], "edges" => [ { "from" => "a", "to" => "b" } ] }

        assert_empty violations(document)
      end

      test "terminates on a document whose edges form a cycle" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                     "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "a" } ] }

        assert_empty violations(document)
      end

      test "reports an entry naming a node that does not exist" do
        document = { "entry" => "ghost", "nodes" => [ { "id" => "a" } ] }

        assert_includes violations(document).map(&:problem), :missing_entry
      end

      test "reports two nodes sharing an id" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "a" } ] }

        assert_equal [ :duplicate_id ], violations(document).map(&:problem)
      end

      test "reports an edge leaving a node that does not exist" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "ghost", "to" => "a" } ] }

        assert_equal [ :missing_edge_source ], violations(document).map(&:problem)
      end

      test "anchors a missing edge target on the node the edge leaves" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

        assert_equal "a", violations(document).first.node
      end

      test "names the missing target as the violation's detail" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

        assert_equal "ghost", violations(document).first.detail
      end

      test "reports an edge pointing at a node that does not exist" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

        assert_equal [ :missing_edge_target ], violations(document).map(&:problem)
      end

      def demanding_registry
        Registry.new.tap do |registry|
          registry.register(StepType.define(:needs) { setting :step, type: :string, required: true })
        end
      end

      test "reports a step left without a setting it cannot run without" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a", "type" => "needs" } ], "edges" => [] }

        assert_equal [ :missing_setting ], violations(document, demanding_registry).map(&:problem)
      end

      def reading_registry
        Registry.new.tap do |registry|
          registry.register(StepType.define(:pick) { output :answer, values: ->(node) { Array(node.config["options"]) } })
          registry.register(StepType.define(:reads) do
            setting :step, type: :previous_step
            setting :answer, from: :step
          end)
        end
      end

      def reading_document(chosen)
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "pick", "options" => [ { "value" => "high" } ] },
                       { "id" => "b", "type" => "reads", "step" => "a", "answer" => chosen } ],
          "edges" => [ { "from" => "a", "to" => "b" } ] }
      end

      test "reports a step reading a value the step it names no longer offers" do
        assert_equal [ :missing_value ], violations(reading_document("gone"), reading_registry).map(&:problem)
      end

      test "accepts a step reading a value the step it names still offers" do
        assert_empty violations(reading_document("high"), reading_registry)
      end

      def deciding_registry
        Registry.new.tap do |registry|
          registry.register(StepType.define(:plain) { })
          registry.register(StepType.define(:decides) do
            output :result, type: :boolean, values: [ true, false ]
            route { |_node, _state| true }
          end)
        end
      end

      def deciding_document(edges)
        { "entry" => "gate",
          "nodes" => [ { "id" => "gate", "type" => "decides" }, { "id" => "yes_step", "type" => "plain" },
                       { "id" => "no_step", "type" => "plain" } ],
          "edges" => edges }
      end

      test "reports a deciding step left without an edge for one of its results" do
        document = deciding_document([ { "from" => "gate", "to" => "yes_step", "on" => true } ])

        assert_includes violations(document, deciding_registry).map(&:problem), :unrouted_value
      end

      test "accepts a deciding step wired for every result it can reach" do
        document = deciding_document([ { "from" => "gate", "to" => "yes_step", "on" => true },
                                       { "from" => "gate", "to" => "no_step", "on" => false } ])

        assert_empty violations(document, deciding_registry)
      end
    end
  end
end
