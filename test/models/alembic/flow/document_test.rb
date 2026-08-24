require "test_helper"

module Alembic
  module Flow
    class DocumentTest < ActiveSupport::TestCase
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
