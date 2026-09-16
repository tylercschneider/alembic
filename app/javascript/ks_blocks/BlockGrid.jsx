import React, { useRef } from "react"
import GridLayout, { useContainerWidth } from "react-grid-layout"
import Alert from "../keystone_ui/react/Alert"
import Button from "../keystone_ui/react/Button"
import Panel from "../keystone_ui/react/Panel"
import Section from "../keystone_ui/react/Section"
import useLayout from "./useLayout"
import { addBlock, dropBlock, gridItems, placeBlocks, removeBlock } from "./blocks"

const SHAPE = { columns: 12, row_height: 60, gap: 10 }
const RESIZE_HANDLES = [ "e", "s", "se" ]

const named = (block_types, key) => block_types.find((blockType) => blockType.key === key)?.name ?? `Unknown block type (${key})`

export default function BlockGrid({ base, token, emptyMessage, ...initial }) {
  const { layout: current, error, send } = useLayout(base, token, initial)
  const { block_types = [], blocks = [], grid = {} } = current
  const { columns, row_height: rowHeight, gap } = { ...SHAPE, ...grid }
  const { width, containerRef, mounted } = useContainerWidth({ measureBeforeMount: true })
  const layout = gridItems(blocks, block_types)
  const dragged = useRef(null)

  const startDragging = (blockType) => (event) => {
    dragged.current = blockType
    event.dataTransfer.setData("text/plain", blockType.key)
  }

  const dropConfig = {
    enabled: true,
    onDragOver: () => dragged.current ? { w: dragged.current.width, h: dragged.current.height } : false
  }

  const dropped = (_layout, item) => {
    if (dragged.current) dropBlock(send, dragged.current.key, item)
    dragged.current = null
  }

  return (
    <div className="lg:grid lg:grid-cols-[16rem_minmax(0,1fr)] lg:gap-6">
      <Section title="Blocks" spacing="sm">
        {block_types.length === 0
          ? <p>There are no blocks to add.</p>
          : <ul>
              {block_types.map((blockType) => (
                <li key={blockType.key} data-block-type={blockType.key} className="flex items-center justify-between gap-2 py-1" draggable="true" onDragStart={startDragging(blockType)}>
                  {blockType.name}
                  <Button variant="secondary" size="sm" type="button" onClick={() => addBlock(send, blockType.key)}>Add</Button>
                </li>
              ))}
            </ul>}
      </Section>
      <Panel data-block-grid-panel>
        {error && <Alert type="error" message={error} className="mb-3" />}
        {blocks.length === 0 && <p>{emptyMessage}</p>}
        <div ref={containerRef} data-block-grid style={{ overflow: "hidden", visibility: mounted ? "visible" : "hidden" }}>
          <GridLayout width={width} layout={layout} gridConfig={{ cols: columns, rowHeight, margin: [ gap, gap ] }} resizeConfig={{ enabled: true, handles: RESIZE_HANDLES }} dragConfig={{ cancel: "[data-remove-block]" }} dropConfig={dropConfig} onDrop={dropped} onDragStop={(placed) => placeBlocks(send, placed)} onResizeStop={(placed) => placeBlocks(send, placed)}>
            {blocks.map((block) => (
              <div key={block.id} data-block={block.id} className="ks-panel p-3 flex items-start justify-between gap-2">
                {named(block_types, block.type)}
                <Button variant="secondary" size="sm" type="button" data-remove-block onClick={() => removeBlock(send, block.id)}>Remove</Button>
              </div>
            ))}
          </GridLayout>
        </div>
      </Panel>
    </div>
  )
}
