require "application_system_test_case"

module Alembic
  class FlowCanvasTest < ApplicationSystemTestCase
    def flow
      @flow ||= Diagnostic.create!(slug: "canvas-system").tap do |diagnostic|
        diagnostic.record_definition(
          "slug" => "canvas-system", "entry" => "start",
          "nodes" => [ { "id" => "start", "type" => "question", "question" => "First",
                         "answers" => [ { "value" => "yes", "label" => "Yes please" } ] },
                       { "id" => "gate", "type" => "condition", "step" => "start", "answer" => "yes" },
                       { "id" => "yes_step", "type" => "question", "question" => "Yes path" } ],
          "edges" => [ { "from" => "start", "to" => "gate" },
                       { "from" => "gate", "to" => "yes_step", "on" => "yes" } ]
        )
      end
    end

    def adrift
      flow.tap do |diagnostic|
        diagnostic.record_definition(diagnostic.definition.merge(
          "nodes" => diagnostic.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))
      end
    end

    def edges
      flow.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    def add_step_named(label)
      find("div[style*='z-index: 9']").click_button(label, match: :first)
    end

    def long_flow
      steps = (1..12).map { |n| { "id" => "s#{n}", "type" => "question", "question" => "Step #{n}" } }
      links = (1...12).map { |n| { "from" => "s#{n}", "to" => "s#{n + 1}" } }

      Diagnostic.create!(slug: "long-flow").tap do |diagnostic|
        diagnostic.record_definition("slug" => "long-flow", "entry" => "s1", "nodes" => steps, "edges" => links)
      end
    end

    test "the connector layer covers a flow taller than the window" do
      canvas_for(long_flow)

      covered = page.evaluate_script(<<~JS)
        (() => {
          const svg = document.querySelector("[data-flow-canvas] svg")
          const surface = svg.parentElement
          const lowest = Math.max(...[...surface.querySelectorAll("[data-step]")].map((c) => c.offsetTop + c.offsetHeight))
          return svg.getBoundingClientRect().height >= lowest
        })()
      JS

      assert covered, "the connector layer stops short of the flow, so lower arrows cannot reach their steps"
    end

    test "draws every step in the flow" do
      canvas_for(flow)

      assert_equal [ "start", "gate", "yes_step" ], step_ids
    end

    test "draws a connector for every edge" do
      canvas_for(flow)

      assert_selector "svg path[marker-end]", count: 2
    end

    test "labels a step by the field its type names it with" do
      canvas_for(flow)

      assert_text "First"
    end

    test "marks a step that cannot be reached" do
      flow.record_definition(flow.definition.merge(
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))

      canvas_for(flow)

      assert_selector "[data-step='adrift']", text: "unreachable"
    end

    test "adding a step from an unconnected branch wires it to that branch" do
      canvas_for(flow)

      step_card("gate").click_button("no")
      add_step_named("Question")

      assert_selector "[data-step]", count: 4
      assert_includes edges.map(&:first), "gate"
    end

    test "removing a connection unlinks the two steps" do
      canvas_for(flow)

      find("[data-connector='start-gate']").hover
      find("[data-connector='start-gate']").click_button("×")

      assert_selector "svg path[marker-end]", count: 1
    end

    test "inserting a step on a connector puts it between the two" do
      canvas_for(flow)

      find("[data-connector='start-gate']").hover
      find("[data-connector='start-gate']").click_button("+")
      add_step_named("Question")

      assert_selector "[data-step]", count: 4
      assert_includes edges, [ "start", "question" ]
    end

    test "opening a step labels each setting its type declares" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector]", text: "Step"
      assert_selector "[data-inspector]", text: "Answer"
    end

    test "opening a condition offers the steps that come before it" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector] select option", text: "First"
    end

    test "opening a condition offers the answers of the step it names" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector] select option", text: "Yes please"
    end

    test "closing the panel leaves the flow drawn" do
      canvas_for(flow)
      step_card("gate").click

      find("[data-inspector]").click_button("×")

      assert_no_selector "[data-inspector]"
      assert_selector "svg path[marker-end]", count: 2
    end

    test "editing a field saves when the field is left" do
      canvas_for(flow)
      step_card("start").click

      fill_in_first_field_with("Changed by hand")

      assert_selector "[data-step='start']", text: "Changed by hand"
    end

    test "dragging a step onto a connector splices it in there" do
      flow.record_definition(flow.definition.merge(
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))
      canvas_for(flow)

      step_card("adrift").drag_to(find("[data-connector='start-gate']"))

      assert_includes edges, [ "start", "adrift" ]
    end

    test "undoing puts back what was there before" do
      canvas_for(flow)
      find("[data-connector='start-gate']").hover
      find("[data-connector='start-gate']").click_button("×")
      assert_selector "svg path[marker-end]", count: 1

      click_button("↶ Undo")

      assert_selector "svg path[marker-end]", count: 2
    end

    test "redoing puts back what was undone" do
      canvas_for(flow)
      find("[data-connector='start-gate']").hover
      find("[data-connector='start-gate']").click_button("×")
      click_button("↶ Undo")
      assert_selector "svg path[marker-end]", count: 2

      click_button("↷ Redo")

      assert_selector "svg path[marker-end]", count: 1
    end

    test "the flow's panel stays out of the way until it is opened" do
      canvas_for(flow)

      assert_no_selector "[data-builder-panel]"
    end

    test "opening the flow's panel shows what has changed" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-builder-panel]", text: "Nothing has changed."
    end

    test "the flow's panel closes again" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("[data-builder-panel]").click_button("×")

      assert_no_selector "[data-builder-panel]"
    end

    test "the flow's panel says which version it stands at" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-history]", text: "Version 1 · never published"
    end

    test "a version is created from the flow's panel" do
      canvas_for(flow)
      step_card("start").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      assert_selector "[data-create-version]", text: "Create version"
    end

    test "the flow's panel links to the definition" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-definition]", text: "Definition"
    end

    test "the flow's panel links to the details" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-details]", text: "Edit details"
    end

    test "the panel lists a change once a step is edited" do
      canvas_for(flow)
      step_card("start").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      assert_selector "[data-change]", text: "Updated"
    end

    test "the panel names a step that cannot be reached" do
      canvas_for(adrift)

      find("[data-open-panel]").click

      assert_selector "[data-problem]", text: "unreachable"
    end

    test "creating a version empties the change list" do
      canvas_for(flow)
      step_card("start").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click
      find("[data-create-version]").click

      assert_selector "[data-builder-panel]", text: "Nothing has changed."
    end

    test "publishing a flow with a problem is refused" do
      canvas_for(adrift)
      find("[data-open-panel]").click

      find("[data-publish]").click

      assert_selector "[data-refusal]"
    end

    test "the flow's panel says when there was nothing to capture" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("[data-create-version]").click

      assert_selector "[data-notice]", text: "Nothing has changed"
    end

    test "the flow's panel says which version it created" do
      canvas_for(flow)
      step_card("start").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      find("[data-create-version]").click

      assert_selector "[data-notice]", text: "Created version 2."
    end

    test "the flow's panel closes when the canvas is clicked" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("body").click

      assert_no_selector "[data-builder-panel]"
    end

    test "the flow's standing leads to its history" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("[data-history]").click

      assert_selector "[data-version]", text: "Version 1"
    end

    test "the flow is renamed from its panel" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "[data-flow-name]", text: "A better name"
    end

    test "the flow's panel says the details were saved" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "[data-notice]", text: "Saved the flow's details."
    end

    test "the builder page follows the flow's new name" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "header h1", text: "A better name"
    end

    test "saving one detail keeps the ones that were already stored" do
      named = flow.tap { |diagnostic| diagnostic.update!(summary: "What this asks about") }
      canvas_for(named)
      find("[data-open-panel]").click

      rename_to("A better name")
      assert_selector "[data-notice]"

      assert_equal "What this asks about", named.reload.summary
    end

    private

    def rename_to(name)
      find("[data-flow-title]").set(name)
      find("[data-builder-panel] h2", match: :first).click
    end

    def fill_in_first_field_with(text)
      field = find("[data-inspector] input[type='text']", match: :first)
      field.set(text)
      find("body").click
    end
  end
end
