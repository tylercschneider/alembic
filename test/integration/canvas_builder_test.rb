require "test_helper"

module Alembic
  class CanvasBuilderTest < ActionDispatch::IntegrationTest
    def diagnostic
      @diagnostic ||= Diagnostic.create!(slug: "canvas").tap do |built|
        built.record_definition(
          "slug" => "canvas", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "text" => "A" }, { "id" => "b", "type" => "question" } ],
          "edges" => [ { "from" => "a", "to" => "b" } ]
        )
      end
    end

    def canvas_path
      alembic.manage_diagnostic_canvas_path(diagnostic)
    end

    def nodes
      diagnostic.reload.definition["nodes"].map { |node| node["id"] }
    end

    test "the diagnostic page mounts the flow canvas" do
      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "[data-flow-canvas]"
    end

    test "the diagnostic page points the canvas at its edit endpoints" do
      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "[data-flow-canvas][data-base=?]", canvas_path
    end

    test "the canvas screen carries the flow as JSON" do
      get "#{canvas_path}.json"

      assert_equal [ "a", "b" ], response.parsed_body["nodes"].map { |node| node["id"] }
    end

    test "the canvas screen carries the registered step types as a palette" do
      get "#{canvas_path}.json"

      assert_includes response.parsed_body["palette"].map { |entry| entry["type"] }, "question"
    end

    test "adding a step records a new version carrying it" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal [ "a", "b", "c" ], nodes
    end

    test "undoing an edit restores what the flow was before it" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      post "#{canvas_path}/undo"

      assert_equal [ "a", "b" ], nodes
    end

    test "undoing records the restoration as a new version rather than discarding one" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_difference -> { diagnostic.definition_versions.count } do
        post "#{canvas_path}/undo"
      end
    end

    test "undoing with nothing behind it leaves the flow alone" do
      post "#{canvas_path}/undo"

      assert_equal [ "a", "b" ], nodes
    end

    test "the canvas says whether there is anything to undo" do
      get "#{canvas_path}.json"

      assert_not response.parsed_body["undoable"]
    end

    test "the canvas says there is something to undo after an edit" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get "#{canvas_path}.json"

      assert response.parsed_body["undoable"]
    end

    test "adding a step from a port connects it to that branch" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "b", on: "no" }

      assert_includes diagnostic.reload.definition["edges"], { "from" => "b", "to" => "c", "on" => "no" }
    end

    test "adding a step from a port leaves the other branches alone" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "b", on: "no" }

      assert_includes diagnostic.reload.definition["edges"].map { |edge| edge["to"] }, "b"
    end

    test "adding a step on an edge puts it between the two steps" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "a", to: "b" }

      assert_equal [ [ "a", "c" ], [ "c", "b" ] ], diagnostic.reload.definition["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    test "configuring a step records the new configuration" do
      patch "#{canvas_path}/steps/a", params: { config: { text: "Changed" } }

      assert_equal "Changed", diagnostic.reload.definition["nodes"].first["text"]
    end

    test "removing a step records a version without it" do
      delete "#{canvas_path}/steps/b"

      assert_equal [ "a" ], nodes
    end

    test "connecting two steps records the new edge" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "b", to: "c" }

      assert_includes diagnostic.reload.definition["edges"].map { |edge| [ edge["from"], edge["to"] ] }, [ "b", "c" ]
    end

    test "disconnecting two steps records a version without the edge" do
      delete "#{canvas_path}/edges", params: { from: "a", to: "b" }

      assert_empty diagnostic.reload.definition["edges"]
    end

    test "every edit records a new immutable version" do
      assert_difference -> { diagnostic.definition_versions.count } do
        post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      end
    end

    test "a refused edit leaves the definition untouched" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_equal [ "a", "b" ], nodes
    end

    test "a refused edit reports why" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_response :unprocessable_entity
    end
  end
end
