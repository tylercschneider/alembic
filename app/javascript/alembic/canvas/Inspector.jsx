import React, { useEffect, useState } from "react"
import Control from "./Control"
import Records from "./Records"
import { action } from "./styles"

const panel = { width: 280, padding: 20, overflowY: "auto", background: "#fff", borderLeft: "1px solid #e5e7eb" }

const Inspector = ({ node, fields, holds, labels, recordLabels, choices, onSave, onDelete, onClose }) => {
  const [ draft, setDraft ] = useState(node.config)
  useEffect(() => setDraft(node.config), [ node.id, node.config ])

  const settle = (next) => {
    setDraft(next)
    if (JSON.stringify(next) !== JSON.stringify(node.config)) onSave(next)
  }

  return (
    <aside style={panel} data-inspector>
      <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8 }}>
        <h2 style={{ fontWeight: 600, marginBottom: 2 }}>{node.label}</h2>
        <button title="Close" onClick={onClose}
                style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1, color: "#6b7280" }}>×</button>
      </div>
      <p style={{ color: "#6b7280", fontSize: 11, marginBottom: 16 }}>{node.id} · {node.type}</p>
      {Object.entries(fields).map(([ name, type ]) => (
        <label key={name} style={{ display: "block" }}>
          <span style={{ display: "block", marginBottom: 3, color: "#374151" }}>{labels[name] || name}</span>
          {type === "list"
            ? <Records holds={holds[name] || {}} labels={recordLabels[name] || {}} rows={draft[name]}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })} />
            : <Control type={type} value={draft[name]} choices={choices[name]}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })} />}
        </label>
      ))}
      <button style={{ ...action, textAlign: "center", color: "#dc2626" }} onClick={onDelete}>Delete step</button>
    </aside>
  )
}

export default Inspector
