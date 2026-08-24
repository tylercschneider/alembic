require "test_helper"

module Alembic
  module Flow
    class CanvasTest < ActiveSupport::TestCase
      def registry
        Registry.new.tap do |built|
          built.register(StepType.define(:ask) { label "Ask"; field :text, :text })
          built.register(StepType.define(:branch) { label "Branch"; outputs :yes, :no })
        end
      end

      def canvas(document)
        Canvas.new(Document.new(document), registry: registry).to_h
      end

      def flow
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "ask", "text" => "Budget?" }, { "id" => "b", "type" => "branch" } ],
          "edges" => [ { "from" => "a", "to" => "b" } ] }
      end

      def side_by_side
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "ask" }, { "id" => "c", "type" => "ask" } ],
          "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" }, { "from" => "b", "to" => "c" } ] }
      end

      test "leaves a step from its bottom when the next one is below" do
        assert_equal "bottom", canvas(flow)["nodes"].first["sourcePosition"]
      end

      test "enters a step at its top when the one before is above" do
        assert_equal "top", canvas(flow)["nodes"].last["targetPosition"]
      end

      test "leaves a step from its side when the next one is beside it" do
        placed = canvas(side_by_side)["nodes"].find { |node| node["id"] == "b" }

        assert_equal "right", placed["sourcePosition"]
      end

      test "enters a step at its side when the one before is beside it" do
        placed = canvas(side_by_side)["nodes"].find { |node| node["id"] == "c" }

        assert_equal "left", placed["targetPosition"]
      end

      test "gives every node a position" do
        assert_equal({ "x" => 0, "y" => 0 }, canvas(flow)["nodes"].first["position"])
      end

      test "labels a node from its first declared field when it has one" do
        assert_equal "Budget?", canvas(flow)["nodes"].first["label"]
      end

      test "falls back to the node id when no field names it" do
        assert_equal "b", canvas(flow)["nodes"].last["label"]
      end

      test "carries every registered step type as a palette entry" do
        assert_equal [ "Ask", "Branch" ], canvas(flow)["palette"].map { |entry| entry["label"] }
      end

      test "carries a palette entry's declared fields" do
        assert_equal({ "text" => "text" }, canvas(flow)["palette"].first["fields"])
      end

      test "carries a palette entry's output ports" do
        assert_equal [ "yes", "no" ], canvas(flow)["palette"].last["ports"]
      end

      test "carries the document's edges" do
        assert_equal [ [ "a", "b" ] ], canvas(flow)["edges"].map { |edge| [ edge["source"], edge["target"] ] }
      end

      test "carries the violations the document has" do
        stranded = flow.merge("nodes" => flow["nodes"] + [ { "id" => "loose", "type" => "ask" } ])

        assert_equal [ "loose" ], canvas(stranded)["violations"].map { |violation| violation["node"] }
      end
    end
  end
end
