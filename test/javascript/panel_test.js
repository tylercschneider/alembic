import { test } from "node:test"
import assert from "node:assert/strict"
import Panel from "../../app/javascript/alembic/canvas/Panel.jsx"

const shown = (tree, marker) => {
  const found = []
  const walk = (node) => {
    if (!node || typeof node !== "object") return
    if (Array.isArray(node)) return node.forEach(walk)
    if (node.props?.[marker] !== undefined) found.push(node)
    walk(node.props?.children)
  }
  walk(tree)
  return found
}

const panel = (given) => Panel({
  flow: { title: "A flow", version: 1, published: 1 },
  changes: [], problems: [], refusal: null, notice: null, ...given
})

test("says nothing has changed when the flow is untouched", () => {
  assert.equal(shown(panel({}), "data-change").length, 0)
})

test("lists a line for each change", () => {
  const tree = panel({ changes: [ "Added “A”", "Moved “B”" ] })

  assert.equal(shown(tree, "data-change").length, 2)
})

test("names each problem it was given", () => {
  const tree = panel({ problems: [ { node: "a", problem: "unreachable" } ] })

  assert.equal(shown(tree, "data-problem").length, 1)
})

test("shows a notice when something was done", () => {
  assert.equal(shown(panel({ notice: "Created version 2." }), "data-notice").length, 1)
})

test("shows a refusal instead of a notice when both arrive", () => {
  const tree = panel({ notice: "Created version 2.", refusal: "Cannot publish." })

  assert.equal(shown(tree, "data-notice").length, 0)
  assert.equal(shown(tree, "data-refusal").length, 1)
})

test("offers the way to the flow's history", () => {
  assert.equal(shown(panel({}), "data-history").length, 1)
})

test("offers the way to the definition and the details", () => {
  const tree = panel({})

  assert.equal(shown(tree, "data-definition").length, 1)
  assert.equal(shown(tree, "data-details").length, 1)
})

test("names a flow that has no title by its slug", () => {
  const tree = panel({ flow: { title: null, slug: "a-flow", version: 1, published: 1 } })

  assert.equal(shown(tree, "data-flow-name")[0].props.children, "a-flow")
})

test("offers the flow's title for editing", () => {
  assert.equal(shown(panel({}), "data-flow-title").length, 1)
})

test("offers the flow's summary for editing", () => {
  assert.equal(shown(panel({}), "data-flow-summary").length, 1)
})

test("offers the flow's start label for editing", () => {
  assert.equal(shown(panel({}), "data-flow-start-label").length, 1)
})
