import { test } from "node:test"
import assert from "node:assert/strict"
import { phrased, worded } from "../../app/javascript/alembic/canvas/changes.js"

test("phrases an added step by name", () => {
  assert.equal(phrased({ action: "added", named: [ "What is your budget?" ] }), "Added “What is your budget?”")
})

test("phrases a moved step by name", () => {
  assert.equal(phrased({ action: "moved", named: [ "Premium tier" ] }), "Moved “Premium tier”")
})

test("phrases a connection between two steps", () => {
  assert.equal(phrased({ action: "connected", named: [ "branch", "basic" ] }), "Connected “branch” → “basic”")
})

test("phrases a change that names nothing", () => {
  assert.equal(phrased({ action: "added", named: [] }), "Added")
})

test("falls back to the bare action it does not know", () => {
  assert.equal(phrased({ action: "reticulated", named: [] }), "reticulated")
})

test("drops a name that is missing rather than quoting nothing", () => {
  assert.equal(phrased({ action: "connected", named: [ "branch", null ] }), "Connected “branch”")
})

test("words a problem against the step it belongs to", () => {
  assert.equal(worded({ node: "branch", problem: "unreachable" }), "“branch” unreachable")
})

test("reads an underscored problem as words", () => {
  assert.equal(worded({ node: "gate", problem: "unmet_requirement" }), "“gate” unmet requirement")
})

test("words a problem belonging to no step", () => {
  assert.equal(worded({ node: null, problem: "missing_entry" }), "missing entry")
})
