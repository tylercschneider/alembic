require "test_helper"

module Alembic
  module Flow
    class ValidatorTest < ActiveSupport::TestCase
      def violations(document)
        Validator.new(Document.new(document)).violations
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
    end
  end
end
