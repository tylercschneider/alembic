import React from "react"
import Port from "./Port"
import { CARD } from "./styles"

const card = { width: CARD, boxSizing: "border-box", background: "#fff", borderRadius: 8 }

const bookendCard = { padding: "8px 14px", textAlign: "center", fontWeight: 600, color: "#6b7280" }

const named = { fontWeight: 600, lineHeight: 1.3 }

const StepCard = ({ node, selected, armed, connecting, onSelect, onArm, onDragEnd, onDragStart }) => {
  const bookend = node.begins_here || node.ends_here
  const pinned = node.begins_here
  const ports = node.ends_here ? [] : node.ports

  return (
    <div ref={node.ref}
         data-step={node.id}
         draggable={!pinned}
         onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
         onDragEnd={onDragEnd}
         onClick={onSelect}
         style={{
           ...card,
           padding: bookend ? 0 : "12px 14px",
           cursor: pinned ? "default" : connecting ? "crosshair" : "grab",
           border: `2px solid ${connecting && !pinned ? "#2563eb" : node.violations.length ? "#dc2626" : selected ? "#2563eb" : "#d1d5db"}`,
           boxShadow: selected ? "0 0 0 3px rgba(37,99,235,.15)" : "0 1px 2px rgba(0,0,0,.05)"
         }}>
      {bookend && <div style={bookendCard}>{node.label}</div>}
      {!bookend && <div style={named}>{node.label}</div>}
      {!bookend && <div style={{ color: "#6b7280", fontSize: 11, marginTop: 2 }}>{node.type}</div>}
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
