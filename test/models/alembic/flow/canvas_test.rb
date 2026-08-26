require "test_helper"

module Alembic
  module Flow
    class CanvasTest < ActiveSupport::TestCase
      def registry
        Registry.new.tap do |built|
          built.register(StepType.define(:ask) do
            step_name "Ask"
            output :answer, values: ->(node) { Array(node.config["options"]) }
            setting :text, type: :string
            setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer }
            names_by :text
          end)
          built.register(StepType.define(:branch) { step_name "Branch"; setting :step, type: :previous_step; setting :answer, from: :step; ports :yes, :no })
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

      def picking
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "ask", "text" => "Budget?", "options" => [ { "value" => "high" } ] },
                       { "id" => "b", "type" => "branch", "step" => "a" } ],
          "edges" => [ { "from" => "a", "to" => "b" } ] }
      end

      def side_by_side
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "ask" }, { "id" => "c", "type" => "ask" } ],
          "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" }, { "from" => "b", "to" => "c" } ] }
      end

      test "gives every node a row and a column" do
        assert_equal [ 0, 0 ], canvas(flow)["nodes"].first.values_at("row", "column")
      end

      test "labels a node from the field its type says names it" do
        assert_equal "Budget?", canvas(flow)["nodes"].first["label"]
      end

      test "falls back to the node id when its type names no field" do
        assert_equal "b", canvas(flow)["nodes"].last["label"]
      end

      test "carries every registered step type as a palette entry" do
        assert_equal [ "Ask", "Branch" ], canvas(flow)["palette"].map { |entry| entry["label"] }
      end

      test "carries what a palette entry's record field holds" do
        entry = canvas(flow)["palette"].first

        assert_equal({ "options" => { "value" => "string", "weight" => "integer" } }, entry["records"])
      end

      test "carries a palette entry's declared fields" do
        assert_equal("string", canvas(flow)["palette"].first["fields"]["text"])
      end

      test "carries a palette entry's output ports" do
        assert_equal [ "yes", "no" ], canvas(flow)["palette"].last["ports"]
      end

      def routed(document, from, to)
        canvas(document)["edges"].find { |edge| edge["source"] == from && edge["target"] == to }
      end

      def branching_flow
        { "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "branch" }, { "id" => "l", "type" => "ask" },
                       { "id" => "r", "type" => "ask" }, { "id" => "end", "type" => "ask" } ],
          "edges" => [ { "from" => "a", "to" => "l", "on" => "yes" }, { "from" => "a", "to" => "r", "on" => "no" },
                       { "from" => "l", "to" => "end" }, { "from" => "r", "to" => "end" } ] }
      end

      test "a step leading to the one below it goes straight down" do
        edge = routed(flow, "a", "b")

        assert_equal [ "bottom", "top", "straight" ], edge.values_at("leaves", "enters", "route")
      end

      test "a branch leaves the side its target lies on" do
        assert_equal "left", routed(branching_flow, "a", "l")["leaves"]
      end

      test "a branch leaves the other side for its other target" do
        assert_equal "right", routed(branching_flow, "a", "r")["leaves"]
      end

      test "a branch turns once into the top of its target" do
        assert_equal [ "top", "turn" ], routed(branching_flow, "a", "l").values_at("enters", "route")
      end

      test "a step merging across into a shared step takes the lane between rows" do
        assert_equal [ "bottom", "top", "lane" ], routed(branching_flow, "r", "end").values_at("leaves", "enters", "route")
      end

      test "a step rejoining one beside it goes straight across" do
        rejoining = { "entry" => "a",
                      "nodes" => [ { "id" => "a", "type" => "branch" }, { "id" => "l", "type" => "ask" }, { "id" => "r", "type" => "ask" } ],
                      "edges" => [ { "from" => "a", "to" => "l", "on" => "yes" }, { "from" => "a", "to" => "r", "on" => "no" },
                                   { "from" => "r", "to" => "l" } ] }

        assert_equal [ "left", "right", "straight" ], routed(rejoining, "r", "l").values_at("leaves", "enters", "route")
      end

      test "a step looping back up detours around" do
        looping = { "entry" => "a",
                    "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "ask" } ],
                    "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "a" } ] }

        assert_equal "detour", routed(looping, "b", "a")["route"]
      end

      test "carries the document's edges" do
        assert_equal [ [ "a", "b" ] ], canvas(flow)["edges"].map { |edge| [ edge["source"], edge["target"] ] }
      end

      test "carries the violations the document has" do
        stranded = flow.merge("nodes" => flow["nodes"] + [ { "id" => "loose", "type" => "ask" } ])

        assert_equal [ "loose" ], canvas(stranded)["violations"].map { |violation| violation["node"] }
      end

      test "offers a step-naming setting the steps that come before that node" do
        assert_equal [ { "value" => "a", "label" => "Budget?" } ], canvas(flow)["nodes"].last["choices"]["step"]
      end

      test "offers a drawing setting the values the step it names outputs" do
        assert_equal [ { "value" => "high" } ], canvas(picking)["nodes"].last["choices"]["answer"]
      end
    end
  end
end
