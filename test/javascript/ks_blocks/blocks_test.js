import { test } from "node:test"
import assert from "node:assert/strict"
import { addBlock, dropBlock, placeBlocks, removeBlock, gridItems } from "../../../app/javascript/ks_blocks/blocks.js"

test("adding a block type sends its key to the page's blocks", () => {
  const sent = []

  addBlock((...request) => sent.push(request), "heading")

  assert.deepEqual(sent, [ [ "/blocks", "POST", { type: "heading" } ] ])
})

test("dropping a block type sends its key and the grid place it was dropped on", () => {
  const sent = []

  dropBlock((...request) => sent.push(request), "text", { x: 3, y: 2 })

  assert.deepEqual(sent, [ [ "/blocks", "POST", { type: "text", x: 3, y: 2 } ] ])
})

test("placing blocks sends each block's id and grid position", () => {
  const sent = []

  placeBlocks((...request) => sent.push(request), [ { i: "b1", x: 0, y: 1, w: 12, h: 1 }, { i: "b2", x: 6, y: 0, w: 6, h: 2 } ])

  assert.deepEqual(sent, [ [ "/blocks", "PATCH", { layout: [ { id: "b1", x: 0, y: 1, w: 12, h: 1 }, { id: "b2", x: 6, y: 0, w: 6, h: 2 } ] } ] ])
})

test("placing blocks also sends each block's size", () => {
  const sent = []

  placeBlocks((...request) => sent.push(request), [ { i: "b1", x: 0, y: 1, w: 8, h: 3 } ])

  assert.deepEqual(sent, [ [ "/blocks", "PATCH", { layout: [ { id: "b1", x: 0, y: 1, w: 8, h: 3 } ] } ] ])
})

test("removing a block sends a delete for that block", () => {
  const sent = []

  removeBlock((...request) => sent.push(request), "b1")

  assert.deepEqual(sent, [ [ "/blocks/b1", "DELETE" ] ])
})

test("a block's grid item carries its type's size limits", () => {
  const blocks = [ { id: "b1", type: "chart", x: 0, y: 0, w: 6, h: 2 } ]
  const types = [ { key: "chart", name: "Chart", width: 6, height: 2, min_width: 4, max_width: 8, min_height: 2, max_height: 3 } ]

  assert.deepEqual(gridItems(blocks, types), [ { i: "b1", x: 0, y: 0, w: 6, h: 2, minW: 4, maxW: 8, minH: 2, maxH: 3 } ])
})

test("a block's grid item carries no limits its type did not set", () => {
  const blocks = [ { id: "b1", type: "text", x: 0, y: 0, w: 6, h: 2 } ]
  const types = [ { key: "text", name: "Text", width: 6, height: 2, min_width: 1, max_width: null, min_height: 1, max_height: null } ]

  assert.deepEqual(gridItems(blocks, types), [ { i: "b1", x: 0, y: 0, w: 6, h: 2, minW: 1, minH: 1 } ])
})

test("a block of a type that cannot be resized has no resize handles", () => {
  const blocks = [ { id: "b1", type: "fixed", x: 0, y: 0, w: 6, h: 2 } ]
  const types = [ { key: "fixed", name: "Fixed", width: 6, height: 2, resizable: false } ]

  assert.equal(gridItems(blocks, types)[0].isResizable, false)
})
