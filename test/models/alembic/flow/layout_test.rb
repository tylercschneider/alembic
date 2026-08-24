require "test_helper"

module Alembic
  module Flow
    class LayoutTest < ActiveSupport::TestCase
      def positions_for(document)
        Layout.new(Document.new(document)).positions
      end

      def branching
        { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" } ],
          "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" } ] }
      end

      test "gives the same document the same positions every time" do
        assert_equal positions_for(branching), positions_for(branching)
      end

      test "places a step below the one it follows" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                     "edges" => [ { "from" => "a", "to" => "b" } ] }
        placed = positions_for(document)

        assert_operator placed["b"]["y"], :>, placed["a"]["y"]
      end

      test "keeps a branching step's successors from overlapping" do
        placed = positions_for(branching)

        assert_not_equal placed["b"]["x"], placed["c"]["x"]
      end

      test "places a branching step's successors at the same depth" do
        placed = positions_for(branching)

        assert_equal placed["b"]["y"], placed["c"]["y"]
      end

      test "lays out a document whose edges form a cycle" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                     "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "a" } ] }

        assert_equal [ "a", "b" ], positions_for(document).keys
      end

      test "still places a step no edge reaches" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "loose" } ], "edges" => [] }

        assert_includes positions_for(document).keys, "loose"
      end

      test "places nothing for an empty document" do
        assert_empty positions_for({})
      end

      test "leaves the document it read untouched" do
        document = branching

        positions_for(document)

        assert_equal branching, document
      end

      test "places every node in the document" do
        document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                     "edges" => [ { "from" => "a", "to" => "b" } ] }

        assert_equal [ "a", "b" ], positions_for(document).keys
      end
    end
  end
end
