require "test_helper"

module Alembic
  module Flow
    class EditsTest < ActiveSupport::TestCase
      def two_step_flow
        Document.new({ "entry" => "a",
                       "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "b", "type" => "plain" } ],
                       "edges" => [ { "from" => "a", "to" => "b" } ] })
      end

      def endpoints(document)
        document.edges.map { |edge| [ edge.from, edge.to ] }
      end

      def three_step_flow
        Document.new({ "entry" => "a",
                       "nodes" => [ { "id" => "a" }, { "id" => "x" }, { "id" => "b" } ],
                       "edges" => [ { "from" => "a", "to" => "x" }, { "from" => "x", "to" => "b" } ] })
      end

      test "rewiring an edge sends it to a different step" do
        document = Document.new({ "entry" => "a",
                                  "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" } ],
                                  "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ] })

        result = document.rewire(from: "a", to: "b", target: "c")

        assert_includes endpoints(result), [ "a", "c" ]
      end

      test "removing a step takes it out of the document's nodes" do
        assert_equal [ "a", "b" ], three_step_flow.remove("x").nodes.map(&:id)
      end

      test "removing a step bridges the steps it sat between" do
        assert_equal [ [ "a", "b" ] ], endpoints(three_step_flow.remove("x"))
      end

      test "removing a step leaves the document it was given untouched" do
        document = three_step_flow

        document.remove("x")

        assert_equal [ "a", "x", "b" ], document.nodes.map(&:id)
      end

      test "inserting a step adds it to the document's nodes" do
        result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

        assert_equal [ "a", "b", "x" ], result.nodes.map(&:id)
      end

      test "inserting a step leaves the document it was given untouched" do
        document = two_step_flow

        document.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

        assert_equal [ [ "a", "b" ] ], endpoints(document)
      end

      test "inserting a step leaves edges it was not asked about alone" do
        document = Document.new({ "entry" => "a",
                                  "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" } ],
                                  "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" } ] })

        result = document.insert({ "id" => "x" }, on: [ "a", "b" ])

        assert_includes endpoints(result), [ "a", "c" ]
      end

      test "inserting a step keeps the port the replaced edge left by" do
        document = Document.new({ "entry" => "a",
                                  "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                                  "edges" => [ { "from" => "a", "to" => "b", "on" => "yes" } ] })

        result = document.insert({ "id" => "x" }, on: [ "a", "b" ])

        assert_equal "yes", result.edges_from("a").first.on
      end

      test "inserting a step on an edge replaces it with an edge in and an edge out" do
        result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

        assert_equal [ [ "a", "x" ], [ "x", "b" ] ], endpoints(result)
      end
    end
  end
end
