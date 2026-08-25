import React from "react"

const Port = ({ name, connected, armed, onArm, connecting }) => (
  <button onClick={(event) => { if (connecting) return; event.stopPropagation(); onArm(event) }}
          title={armed ? "Now choose a step to connect to" : "Connect this branch"}
          style={{
            padding: "1px 8px", marginRight: 4, borderRadius: 999, fontSize: 11, cursor: "pointer",
            border: `1px solid ${armed ? "#2563eb" : connected ? "#d1d5db" : "#f59e0b"}`,
            background: armed ? "#2563eb" : "#fff", color: armed ? "#fff" : connected ? "#6b7280" : "#b45309"
          }}>{name || "next"}</button>
)

export default Port
