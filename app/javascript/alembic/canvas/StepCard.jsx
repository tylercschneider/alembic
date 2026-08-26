import React from "react"
import Port from "./Port"
import { CARD } from "./styles"

const card = { width: CARD, boxSizing: "border-box", background: "#fff", borderRadius: 8 }

const bookend = { padding: "8px 14px", textAlign: "center", fontWeight: 600, color: "#6b7280" }

const named = { fontWeight: 600, lineHeight: 1.3 }

const StepCard = ({ node, selected, armed, connecting, onSelect, onArm, onDragEnd, onDragStart }) => {
  const fixed = node.begins_here || node.ends_here
  const ports = node.ends_here ? [] : node.ports

  return (
    <div ref={node.ref}
         data-step={node.id}
         draggable={!fixed}
         onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
         onDragEnd={onDragEnd}
         onClick={onSelect}
         style={{
           ...card,
           padding: fixed ? 0 : "12px 14px",
           cursor: fixed ? "default" : connecting ? "crosshair" : "grab",
           border: `2px solid ${connecting && !fixed ? "#2563eb" : node.violations.length ? "#dc2626" : selected ? "#2563eb" : "#d1d5db"}`,
           boxShadow: selected ? "0 0 0 3px rgba(37,99,235,.15)" : "0 1px 2px rgba(0,0,0,.05)"
         }}>
      {fixed && <div style={bookend}>{node.label}</div>}
      {!fixed && <div style={named}>{node.label}</div>}
      {!fixed && <div style={{ color: "#6b7280", fontSize: 11, marginTop: 2 }}>{node.type}</div>}
      {node.violations.map((violation) => (
        <div key={violation.problem + violation.detail} style={{ color: "#dc2626", fontSize: 11, padding: "0 14px 6px" }}>
          {violation.problem.replace(/_/g, " ")}{violation.detail ? `: ${violation.detail}` : ""}
        </div>
      ))}
      {ports.length > 0 && (
        <div style={{ padding: node.begins_here ? "0 14px 8px" : "10px 0 0" }}>
          {ports.map((port) => (
            <Port key={port} name={port} connected={node.connected.includes(port)}
                  connecting={connecting} armed={armed === port} onArm={(event) => onArm(port, event)} />
          ))}
        </div>
      )}
    </div>
  )
}

export default StepCard
