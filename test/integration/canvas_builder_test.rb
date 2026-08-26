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
      diagnostic.reload.document["nodes"].map { |node| node["id"] }
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

    test "redoing puts back what was undone" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/undo"

      post "#{canvas_path}/redo"

      assert_equal [ "a", "b", "c" ], nodes
    end

    test "the canvas says whether there is anything to redo" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/undo"

      get "#{canvas_path}.json"

      assert response.parsed_body["redoable"]
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

      assert_includes diagnostic.reload.document["edges"], { "from" => "b", "to" => "c", "on" => "no" }
    end

    test "adding a step from a port leaves the other branches alone" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "b", on: "no" }

      assert_includes diagnostic.reload.document["edges"].map { |edge| edge["to"] }, "b"
    end

    test "adding a step on an edge puts it between the two steps" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "a", to: "b" }

      assert_equal [ [ "a", "c" ], [ "c", "b" ] ], diagnostic.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    test "configuring a step records the new configuration" do
      patch "#{canvas_path}/steps/a", params: { config: { text: "Changed" } }

      assert_equal "Changed", diagnostic.reload.document["nodes"].first["text"]
    end

    test "removing a step records a version without it" do
      delete "#{canvas_path}/steps/b"

      assert_equal [ "a" ], nodes
    end

    test "connecting two steps records the new edge" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "b", to: "c" }

      assert_includes diagnostic.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }, [ "b", "c" ]
    end

    test "disconnecting two steps records a version without the edge" do
      delete "#{canvas_path}/edges", params: { from: "a", to: "b" }

      assert_empty diagnostic.reload.document["edges"]
    end

    test "editing records no new version" do
      assert_no_difference -> { diagnostic.definition_versions.count } do
        post "#{canvas_path}/steps", params: { id: "c", type: "question" }
        patch "#{canvas_path}/steps/a", params: { config: { question: "Changed" } }
        post "#{canvas_path}/edges", params: { from: "a", to: "c" }
        delete "#{canvas_path}/steps/c"
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

    test "configuring a step stores a number for a setting declared as one" do
      patch "#{canvas_path}/steps/a", params: { config: { answers: [ { value: "low", weight: "4" } ] } }

      stored = diagnostic.reload.document["nodes"].first

      assert_equal 4, stored["answers"].first["weight"]
    end

    test "configuring a step refuses more choices than the setting allows" do
      post "#{canvas_path}/steps", params: { id: "n", type: "notify" }
      before = diagnostic.reload.definition_cursor

      patch "#{canvas_path}/steps/n", params: { config: { channels: %w[email sms push] } }

      assert_equal before, diagnostic.reload.definition_cursor
    end

    test "adding a step writes it into the live document" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_includes diagnostic.reload.document["nodes"].map { |node| node["id"] }, "c"
    end

    test "the builder renders the document being edited, not the recorded version" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get alembic.manage_diagnostic_path(diagnostic)

      drawn = JSON.parse(css_select("[data-flow-canvas]").first["data-flow"])

      assert_includes drawn["nodes"].map { |node| node["id"] }, "c"
    end

    test "cutting a version records the document being edited" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_difference -> { diagnostic.definition_versions.count } do
        post "#{canvas_path}/versions"
      end
    end

    test "adding a step records what changed" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal "added", diagnostic.reload.changes_since_version.last["action"]
    end

    test "a change names the step it touched" do
      patch "#{canvas_path}/steps/a", params: { config: { question: "What is your budget?" } }

      assert_equal [ "What is your budget?" ], diagnostic.reload.changes_since_version.last["named"]
    end

    test "a change falls back to the step id when it has no name" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal [ "c" ], diagnostic.reload.changes_since_version.last["named"]
    end

    test "changes accumulate in the order the edits happened" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "a", to: "c" }

      assert_equal %w[added connected], diagnostic.reload.changes_since_version.map { |change| change["action"] }
    end

    test "a refused edit records nothing" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_empty diagnostic.reload.changes_since_version.to_a
    end

    test "publishing refuses a document with problems" do
      post "#{canvas_path}/steps", params: { id: "adrift", type: "question" }

      post "#{canvas_path}/publish"

      assert_response :unprocessable_entity
      assert_nil diagnostic.reload.published_version
    end

    test "publishing a sound document marks it for visitors" do
      post "#{canvas_path}/publish"

      assert_equal diagnostic.reload.definition_versions.last, diagnostic.published_version
    end

    test "the canvas carries what has changed since the last version" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal [ "Added “c”" ], response.parsed_body["changes"]
    end

    test "the canvas ships a change as a sentence, not the document undo keeps" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_kind_of String, response.parsed_body["changes"].first
    end

    test "the change list empties when a version is cut" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/versions"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_empty response.parsed_body["changes"]
    end

    test "the canvas carries which version this flow stands at" do
      post "#{canvas_path}/versions"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal diagnostic.reload.current_definition_version.number, response.parsed_body["flow"]["version"]
    end

    test "the canvas carries which version visitors run" do
      post "#{canvas_path}/publish"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal diagnostic.reload.published_version.number, response.parsed_body["flow"]["published"]
    end

    test "the canvas carries where the definition is edited" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal alembic.edit_manage_diagnostic_definition_path(diagnostic), response.parsed_body["flow"]["definition_url"]
    end

    test "the canvas carries where the details are edited" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal alembic.edit_manage_diagnostic_path(diagnostic), response.parsed_body["flow"]["details_url"]
    end

    test "a refused publish says it could not publish and why" do
      post "#{canvas_path}/steps", params: { id: "adrift", type: "question" }

      post "#{canvas_path}/publish"

      assert_equal "Cannot publish: “adrift” is unreachable.", response.parsed_body["error"]
    end

    test "creating a version says which one it created" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      post "#{canvas_path}/versions"

      assert_equal "Created version 2.", response.parsed_body["notice"]
    end

    test "creating a version says when there was nothing to capture" do
      post "#{canvas_path}/versions"

      assert_equal "Nothing has changed since version 1.", response.parsed_body["notice"]
    end

    test "publishing says which version visitors now run" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "b", to: "c" }

      post "#{canvas_path}/publish"

      assert_equal "Published version 2. Visitors run it now.", response.parsed_body["notice"]
    end

    test "publishing says when visitors already run this version" do
      post "#{canvas_path}/publish"

      post "#{canvas_path}/publish"

      assert_equal "Visitors already run version 1.", response.parsed_body["notice"]
    end

    test "the versions page lists a flow's versions newest first" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/versions"

      get alembic.manage_diagnostic_versions_path(diagnostic)

      assert_select "[data-version]:first-of-type", text: /2/
    end

    test "the versions page marks the version visitors run" do
      post "#{canvas_path}/publish"

      get alembic.manage_diagnostic_versions_path(diagnostic)

      assert_select "[data-live]"
    end

    test "the versions page shows what a version captured" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/versions"

      get alembic.manage_diagnostic_versions_path(diagnostic)

      assert_select "[data-captured]", text: /Added/
    end

    test "the versions page lists a version that captured nothing" do
      get alembic.manage_diagnostic_versions_path(diagnostic)

      assert_select "[data-version]", count: 1
    end

    test "the history offers a way back to an earlier version" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/versions"

      get alembic.manage_diagnostic_versions_path(diagnostic)

      assert_select "[data-return]", count: 1
    end

    test "returning from the history makes that version the live document" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/versions"
      first = diagnostic.definition_versions.order(:number).first

      post alembic.return_manage_diagnostic_version_path(diagnostic, first)

      assert_equal first.definition, diagnostic.reload.document
    end
  end
end
