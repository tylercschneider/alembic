require "application_system_test_case"

module Alembic
  class FlowCanvasTest < ApplicationSystemTestCase
    def flow
      @flow ||= Diagnostic.create!(slug: "canvas-system").tap do |diagnostic|
        diagnostic.record_definition(
          "slug" => "canvas-system", "entry" => "start",
          "nodes" => [ { "id" => "start", "type" => "question", "text" => "First" },
                       { "id" => "gate", "type" => "condition", "answer" => "start", "equals" => "yes" },
                       { "id" => "yes_step", "type" => "question", "text" => "Yes path" } ],
          "edges" => [ { "from" => "start", "to" => "gate" },
                       { "from" => "gate", "to" => "yes_step", "on" => "yes" } ]
        )
      end
    end

    def edges
      flow.reload.definition["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    def add_step_named(label)
      find("div[style*='z-index: 9']").click_button(label, match: :first)
    end

    def long_flow
      steps = (1..12).map { |n| { "id" => "s#{n}", "type" => "question", "text" => "Step #{n}" } }
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
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "text" => "Adrift" } ]))

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

      assert_selector "aside", text: "Answer"
      assert_selector "aside", text: "Equals"
    end

    test "closing the panel leaves the flow drawn" do
      canvas_for(flow)
      step_card("gate").click

      find("aside").click_button("×")

      assert_no_selector "aside"
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
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "text" => "Adrift" } ]))
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

    private

    def fill_in_first_field_with(text)
      field = find("aside input[type='text']", match: :first)
      field.set(text)
      find("body").click
    end
  end
end
