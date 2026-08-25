import React from "react"
import Connector from "./Connector"

const ConnectorLayer = ({ links, extent, dragging, onInsert, onRemove, onDrop }) => (
  <>
    <svg width={extent.width} height={extent.height}
         style={{ position: "absolute", top: 0, left: 0, pointerEvents: "none", zIndex: 1 }}>
      <defs>
        <marker id="alembic-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto">
          <path d="M 0 0 L 10 5 L 0 10 z" fill="#9ca3af" />
        </marker>
      </defs>
      {links.map((link) => (
        <path key={link.id} fill="none" stroke="#9ca3af" strokeWidth="1.5" markerEnd="url(#alembic-arrow)" d={link.path} />
      ))}
    </svg>

    {links.filter((link) => link.label).map((link) => (
      <div key={`${link.id}-label`}
           style={{ position: "absolute", left: link.midX - 10, top: link.midY - 18, zIndex: 3,
                    fontSize: 11, color: "#6b7280", background: "#fafafa", padding: "0 3px" }}>{link.label}</div>
    ))}

    {links.map((link) => (
      <Connector key={link.id} link={link} dragging={Boolean(dragging)}
                 onInsert={() => onInsert(link)} onRemove={() => onRemove(link)} onDrop={() => onDrop(link)} />
    ))}
  </>
)

export default ConnectorLayer
