import React from "react"
import Control from "./Control"
import { action } from "./styles"

const Records = ({ holds, labels, rows, onChange, onSettle }) => {
  const kept = Array.isArray(rows) ? rows : []
  const amend = (index, name, next, settle) => {
    const updated = kept.map((row, at) => (at === index ? { ...row, [name]: next } : row))
    settle ? onSettle(updated) : onChange(updated)
  }

  return (
    <div style={{ marginBottom: 12 }}>
      {kept.map((row, index) => (
        <div key={index} style={{ border: "1px solid #e5e7eb", borderRadius: 6, padding: "8px 8px 2px", marginBottom: 6 }}>
          {Object.entries(holds).map(([ name, type ]) => (
            <label key={name} style={{ display: "block" }}>
              <span style={{ display: "block", marginBottom: 2, color: "#6b7280", fontSize: 11 }}>{(labels || {})[name] || name}</span>
              <Control type={type} value={row[name]}
                       onChange={(next) => amend(index, name, next, false)}
                       onSettle={(next) => amend(index, name, next, true)} />
            </label>
          ))}
          <button style={{ ...action, textAlign: "center", fontSize: 11, padding: "3px 8px" }}
                  onClick={() => onSettle(kept.filter((_, at) => at !== index))}>Remove</button>
        </div>
      ))}
      <button style={{ ...action, textAlign: "center" }} onClick={() => onSettle([ ...kept, {} ])}>Add</button>
    </div>
  )
}

export default Records
