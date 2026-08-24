require "test_helper"

module Alembic
  module Flow
    class DocumentTest < ActiveSupport::TestCase
      test "exposes an edge's source and target" do
        document = Document.new({ "edges" => [ { "from" => "a", "to" => "b" } ] })

        assert_equal [ [ "a", "b" ] ], document.edges.map { |edge| [ edge.from, edge.to ] }
      end

      test "exposes the named output port an edge leaves by" do
        document = Document.new({ "edges" => [ { "from" => "a", "to" => "b", "on" => "yes" } ] })

        assert_equal "yes", document.edges.first.on
      end

      test "leaves the port empty when an edge names none" do
        document = Document.new({ "edges" => [ { "from" => "a", "to" => "b" } ] })

        assert_nil document.edges.first.on
      end

      test "exposes a node's type" do
        document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question" } ] })

        assert_equal "question", document.nodes.first.type
      end

      test "keeps everything else on a node as its configuration" do
        document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question", "text" => "Budget?" } ] })

        assert_equal({ "text" => "Budget?" }, document.nodes.first.config)
      end

      test "exposes the id of each node" do
        document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question" } ] })

        assert_equal [ "a" ], document.nodes.map(&:id)
      end
    end
  end
end
