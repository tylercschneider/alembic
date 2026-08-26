import React, { useState } from "react"
import { plus } from "./styles"

const Connector = ({ link, onInsert, onRemove, onDrop, dragging }) => {
  const [ over, setOver ] = useState(false)
  const showing = over || dragging

  return (
    <div data-connector={`${link.source}-${link.target}`}
         style={{ position: "absolute", left: link.midX - 34, top: link.midY - 20, width: 68, height: 40, zIndex: 4 }}
         onMouseEnter={() => setOver(true)} onMouseLeave={() => setOver(false)}
         onDragEnter={() => setOver(true)} onDragLeave={() => setOver(false)}
         onDragOver={(event) => { event.preventDefault(); event.dataTransfer.dropEffect = "move" }}
         onDrop={(event) => { event.preventDefault(); setOver(false); onDrop() }}>
      {link.label != null && link.label !== "" && (
        <div data-connector-label
             style={{ position: "absolute", inset: 0, display: "flex", justifyContent: "center", alignItems: "center",
                      fontSize: 11, color: "#6b7280", pointerEvents: "none",
                      opacity: showing ? 0 : 1, transition: "opacity .12s" }}>
          <span style={{ background: "#fff", padding: "0 4px", borderRadius: 3 }}>{String(link.label)}</span>
        </div>
      )}
      <div style={{ display: "flex", gap: 4, justifyContent: "center", alignItems: "center", height: "100%",
                    opacity: showing ? 1 : 0, transition: "opacity .12s" }}>
        <button title={dragging ? "Move the step here" : "Insert a step here"} onClick={onInsert}
                style={{ ...plus, borderColor: dragging && over ? "#2563eb" : "#d1d5db" }}>+</button>
        {!dragging && (
          <button title="Remove this connection" onClick={onRemove}
                  style={{ ...plus, color: "#dc2626", borderColor: "#e5b4b4" }}>×</button>
        )}
      </div>
    </div>
  )
}

export default Connector
