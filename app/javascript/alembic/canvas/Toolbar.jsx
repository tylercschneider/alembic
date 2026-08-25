import React from "react"
import { action, plus } from "./styles"

const stepper = { ...action, width: "auto", marginBottom: 0, padding: "5px 12px" }

const Stepper = ({ label, title, idle, enabled, onUse }) => (
  <button title={enabled ? title : idle} disabled={!enabled} onClick={onUse}
          style={{ ...stepper, opacity: enabled ? 1 : 0.4, cursor: enabled ? "pointer" : "default" }}>{label}</button>
)

const Toolbar = ({ empty, undoable, redoable, onAdd, onUndo, onRedo }) => (
  <div style={{ position: "absolute", top: 16, left: 16, zIndex: 5, display: "flex", gap: 8 }}>
    {empty && <button style={plus} title="Add a step" onClick={onAdd}>+</button>}
    <Stepper label="↶ Undo" title="Undo the last change" idle="Nothing to undo" enabled={undoable} onUse={onUndo} />
    <Stepper label="↷ Redo" title="Redo the change you undid" idle="Nothing to redo" enabled={redoable} onUse={onRedo} />
  </div>
)

export default Toolbar
