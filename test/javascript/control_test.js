import { test } from "node:test"
import assert from "node:assert/strict"
import Control from "../../app/javascript/alembic/canvas/Control.jsx"

const control = (given) => Control({
  type: "previous_step", value: "a", choices: [ { value: "a", label: "Budget?" } ],
  onChange: () => {}, onSettle: () => {}, ...given
})

test("offers a step that comes before as a choice rather than free text", () => {
  assert.equal(control({}).type, "select")
})
