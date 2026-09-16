export const addBlock = (send, type) => send("/blocks", "POST", { type })

export const dropBlock = (send, type, { x, y }) => send("/blocks", "POST", { type, x, y })

export const placeBlocks = (send, layout) => send("/blocks", "PATCH", { layout: layout.map(({ i, x, y, w, h }) => ({ id: i, x, y, w, h })) })

export const removeBlock = (send, id) => send(`/blocks/${id}`, "DELETE")

export const gridItems = (blocks, block_types) => blocks.map(({ id, x, y, w, h, type }) => {
  const limits = block_types.find((blockType) => blockType.key === type) ?? {}
  const named = { minW: limits.min_width, maxW: limits.max_width, minH: limits.min_height, maxH: limits.max_height }
  const set = Object.fromEntries(Object.entries(named).filter(([ , limit ]) => limit != null))

  return { i: id, x, y, w, h, ...set, ...(limits.resizable === false && { isResizable: false }) }
})
