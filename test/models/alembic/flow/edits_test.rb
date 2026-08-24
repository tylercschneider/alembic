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

      test "inserting a step on an edge replaces it with an edge in and an edge out" do
        result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

        assert_equal [ [ "a", "x" ], [ "x", "b" ] ], endpoints(result)
      end
    end
  end
end
