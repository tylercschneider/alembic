import React from "react"
import { toggled } from "./choices"

export const control = {
  width: "100%", marginBottom: 12, padding: "6px 8px",
  border: "1px solid #d1d5db", borderRadius: 4, fontSize: 13, boxSizing: "border-box"
}

const offered = (choices) =>
  (choices || []).map((choice) => (typeof choice === "object" ? choice : { value: choice, label: choice }))

const Control = ({ type, value, choices, onChange, onSettle }) => {
  if (type === "boolean") return <input type="checkbox" checked={Boolean(value)} onChange={(e) => onSettle(e.target.checked)} />

  if (type === "select" || type === "previous_step") {
    return <select style={control} value={value ?? ""} onChange={(e) => onSettle(e.target.value)}>
      <option value=""></option>
      {offered(choices).map((choice) => <option key={choice.value} value={choice.value}>{choice.label}</option>)}
    </select>
  }

  if (type === "multi_select") {
    const chosen = Array.isArray(value) ? value : []
    const toggle = (choice) => onSettle(toggled(chosen, choice))
    return <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
      {(choices || []).map((choice) => (
        <label key={choice} style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
          <input type="checkbox" checked={chosen.includes(choice)} onChange={() => toggle(choice)} />
          <span>{choice}</span>
        </label>
      ))}
    </div>
  }

  if (type === "integer" || type === "float") {
    return <input style={control} type="number" step={type === "integer" ? "1" : "any"} value={value ?? ""}
                  onChange={(e) => onChange(e.target.value)} onBlur={(e) => onSettle(e.target.value)} />
  }

  return <input style={control} type="text" value={value ?? ""}
                onChange={(e) => onChange(e.target.value)} onBlur={(e) => onSettle(e.target.value)} />
}

export default Control
