import { test } from "node:test"
import assert from "node:assert/strict"
import { standing } from "../../app/javascript/alembic/canvas/flow.js"

test("reads the version and what visitors run", () => {
  assert.equal(standing({ version: 84, published: 84 }), "Version 84 · visitors run 84")
})

test("says when visitors are still on an older version", () => {
  assert.equal(standing({ version: 90, published: 84 }), "Version 90 · visitors run 84")
})

test("says when nothing has been published", () => {
  assert.equal(standing({ version: 3, published: null }), "Version 3 · nothing published")
})

test("says when no version has been created", () => {
  assert.equal(standing({ version: null, published: null }), "No version yet · nothing published")
})
