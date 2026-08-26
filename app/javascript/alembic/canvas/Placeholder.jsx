import React from "react"
import { CARD } from "./styles"

const waiting = {
  width: CARD, boxSizing: "border-box", padding: "10px 14px", borderRadius: 8, textAlign: "center",
  border: "2px dashed #f59e0b", background: "#fffbeb", color: "#b45309", fontSize: 12, cursor: "pointer"
}

const Placeholder = ({ node, dragging, onFill, onDrop }) => (
  <div ref={node.ref} data-placeholder={node.id}
       title={`Choose the step “${node.label}” should lead to`}
       onClick={onFill}
       onDragOver={(event) => { if (dragging) { event.preventDefault(); event.dataTransfer.dropEffect = "move" } }}
       onDrop={(event) => { event.preventDefault(); onDrop() }}
       style={{ ...waiting, ...(dragging ? { borderColor: "#2563eb", background: "#eff6ff", color: "#1e40af" } : {}) }}>
    <div style={{ fontWeight: 600 }}>{node.label}</div>
    <div style={{ fontSize: 11 }}>{dragging ? "drop a step here" : "leads nowhere yet — click to choose"}</div>
  </div>
)

export default Placeholder
