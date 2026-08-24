import React from "react"
import { createRoot } from "react-dom/client"
import { ReactFlow, Background, Controls } from "@xyflow/react"
import "@xyflow/react/dist/style.css"

const EMPTY_FLOW = { nodes: [], edges: [] }

const Canvas = ({ nodes, edges }) => (
  <ReactFlow nodes={nodes} edges={edges} fitView>
    <Background />
    <Controls />
  </ReactFlow>
)

const flowFrom = (element) => {
  try {
    return JSON.parse(element.dataset.flow)
  } catch {
    return EMPTY_FLOW
  }
}

const start = () =>
  document.querySelectorAll("[data-flow-canvas]").forEach((element) => {
    createRoot(element).render(<Canvas {...flowFrom(element)} />)
  })

document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", start) : start()
