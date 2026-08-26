import React from "react"
import Port from "./Port"
import { CARD } from "./styles"

const card = { width: CARD, boxSizing: "border-box", padding: "12px 14px", background: "#fff", borderRadius: 8, cursor: "grab" }

const ending = { padding: "8px 14px", textAlign: "center", fontWeight: 600, color: "#6b7280" }

const StepCard = ({ node, selected, armed, connecting, onSelect, onArm, onDragEnd, onDragStart }) => (
  <div ref={node.ref}
       data-step={node.id}
       draggable
       onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
       onDragEnd={onDragEnd}
       onClick={onSelect}
       style={{
         ...card,
         ...(node.ends_here ? { padding: 0 } : {}),
         cursor: connecting ? "crosshair" : "grab",
         border: `2px solid ${connecting ? "#2563eb" : node.violations.length ? "#dc2626" : selected ? "#2563eb" : "#d1d5db"}`,
         boxShadow: selected ? "0 0 0 3px rgba(37,99,235,.15)" : "0 1px 2px rgba(0,0,0,.05)"
       }}>
    {node.ends_here && <div style={ending}>{node.label}</div>}
    {!node.ends_here && <div style={{ fontWeight: 600, lineHeight: 1.3 }}>{node.label}</div>}
    {!node.ends_here && <div style={{ color: "#6b7280", fontSize: 11, marginTop: 2 }}>{node.type}</div>}
    {node.violations.map((violation) => (
      <div key={violation.problem + violation.detail} style={{ color: "#dc2626", fontSize: 11, marginTop: 6 }}>
        {violation.problem.replace(/_/g, " ")}{violation.detail ? `: ${violation.detail}` : ""}
      </div>
    ))}
    <div style={{ marginTop: node.ends_here ? 0 : 10 }}>
      {(node.ends_here ? [] : node.ports.length ? node.ports : [ null ]).map((port) => (
        <Port key={port || "next"} name={port} connected={node.connected.includes(port)}
              connecting={connecting} armed={armed === (port || "")} onArm={(event) => onArm(port || "", event)} />
      ))}
    </div>
  </div>
)

export default StepCard
