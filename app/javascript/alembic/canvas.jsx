import React, { useCallback, useEffect, useMemo, useState } from "react"
import { createRoot } from "react-dom/client"
import { ReactFlow, Background, Controls, Handle, Position } from "@xyflow/react"
import "@xyflow/react/dist/style.css"

const PANEL = { width: 260, padding: 16, overflowY: "auto", background: "#fff", borderLeft: "1px solid #e5e7eb", fontSize: 13 }
const SIDEBAR = { ...PANEL, borderLeft: "none", borderRight: "1px solid #e5e7eb" }
const BUTTON = { display: "block", width: "100%", marginBottom: 6, padding: "6px 10px", textAlign: "left", cursor: "pointer", border: "1px solid #d1d5db", borderRadius: 6, background: "#fff" }
const CONTROL = { width: "100%", marginBottom: 10, padding: "5px 7px", border: "1px solid #d1d5db", borderRadius: 4, fontSize: 13, boxSizing: "border-box" }

const StepNode = ({ data, selected }) => {
  const ports = data.ports.length ? data.ports : [ null ]

  return (
    <div style={{
      minWidth: 170, padding: "8px 12px", borderRadius: 6, background: "#fff", fontSize: 13,
      border: `2px solid ${data.violations.length ? "#dc2626" : selected ? "#2563eb" : "#9ca3af"}`
    }}>
      <Handle type="target" position={Position.Left} />
      <div style={{ fontWeight: 600 }}>{data.label}</div>
      <div style={{ color: "#6b7280", fontSize: 11 }}>{data.type}</div>
      {data.violations.map((violation) => (
        <div key={violation.problem + violation.detail} style={{ color: "#dc2626", fontSize: 11, marginTop: 4 }}>
          {violation.problem.replace(/_/g, " ")}{violation.detail ? `: ${violation.detail}` : ""}
        </div>
      ))}
      {ports.map((port, index) => (
        <Handle key={port || "out"} id={port || undefined} type="source" position={Position.Right}
                style={{ top: `${((index + 1) * 100) / (ports.length + 1)}%` }} />
      ))}
      {data.ports.length > 0 && (
        <div style={{ display: "flex", justifyContent: "flex-end", gap: 6, marginTop: 4, fontSize: 10, color: "#6b7280" }}>
          {data.ports.map((port) => <span key={port}>{port}</span>)}
        </div>
      )}
    </div>
  )
}

const Control = ({ type, value, onChange }) => {
  if (type === "boolean") return <input type="checkbox" checked={Boolean(value)} onChange={(e) => onChange(e.target.checked)} />
  if (type === "number") return <input style={CONTROL} type="number" value={value ?? ""} onChange={(e) => onChange(e.target.value)} />
  if (type === "list") {
    const lines = Array.isArray(value) ? value.join("\n") : value ?? ""
    return <textarea style={{ ...CONTROL, height: 70 }} value={lines} onChange={(e) => onChange(e.target.value.split("\n").filter(Boolean))} />
  }
  if (type === "text") return <textarea style={{ ...CONTROL, height: 60 }} value={value ?? ""} onChange={(e) => onChange(e.target.value)} />
  return <input style={CONTROL} type="text" value={value ?? ""} onChange={(e) => onChange(e.target.value)} />
}

const Inspector = ({ node, fields, onSave, onDelete }) => {
  const [ draft, setDraft ] = useState(node.config)
  useEffect(() => setDraft(node.config), [ node.id, node.config ])

  return (
    <aside style={PANEL}>
      <h2 style={{ fontWeight: 600, marginBottom: 2 }}>{node.label}</h2>
      <p style={{ color: "#6b7280", fontSize: 11, marginBottom: 12 }}>{node.id} · {node.type}</p>
      {Object.entries(fields).map(([ name, type ]) => (
        <label key={name} style={{ display: "block", marginBottom: 4 }}>
          <span style={{ display: "block", marginBottom: 2, color: "#374151" }}>{name}</span>
          <Control type={type} value={draft[name]} onChange={(next) => setDraft({ ...draft, [name]: next })} />
        </label>
      ))}
      <button style={{ ...BUTTON, textAlign: "center" }} onClick={() => onSave(draft)}>Save</button>
      <button style={{ ...BUTTON, textAlign: "center", color: "#dc2626" }} onClick={onDelete}>Delete step</button>
    </aside>
  )
}

const Palette = ({ entries, onAdd }) => (
  <aside style={SIDEBAR}>
    <h2 style={{ fontWeight: 600, marginBottom: 10 }}>Steps</h2>
    {entries.map((entry) => (
      <button key={entry.type} style={BUTTON} onClick={() => onAdd(entry)}>
        {entry.label}
        <span style={{ display: "block", color: "#6b7280", fontSize: 11 }}>{entry.type}</span>
      </button>
    ))}
  </aside>
)

const Canvas = ({ base, token, initial }) => {
  const [ flow, setFlow ] = useState(initial)
  const [ selected, setSelected ] = useState(null)
  const [ error, setError ] = useState(null)

  const send = useCallback(async (path, method, body) => {
    const response = await fetch(base + path, {
      method,
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: body && JSON.stringify(body)
    })
    if (!response.ok) {
      setError((await response.json().catch(() => ({}))).error || "That change was refused")
      return
    }
    setError(null)
    setFlow(await (await fetch(base + ".json", { headers: { Accept: "application/json" } })).json())
  }, [ base, token ])

  const violationsFor = useMemo(() => {
    const grouped = {}
    flow.violations.forEach((violation) => (grouped[violation.node] ||= []).push(violation))
    return grouped
  }, [ flow.violations ])

  const nodes = useMemo(() => flow.nodes.map((node) => ({
    id: node.id, position: node.position, type: "step", selected: node.id === selected,
    data: { ...node, violations: violationsFor[node.id] || [] }
  })), [ flow.nodes, violationsFor, selected ])

  const edges = useMemo(() => flow.edges.map((edge) => ({
    ...edge, sourceHandle: edge.label || null
  })), [ flow.edges ])

  const nextId = (type) => {
    const taken = new Set(flow.nodes.map((node) => node.id))
    let candidate = type
    let suffix = 2
    while (taken.has(candidate)) candidate = `${type}_${suffix++}`
    return candidate
  }

  const selectedNode = flow.nodes.find((node) => node.id === selected)
  const selectedFields = flow.palette.find((entry) => entry.type === selectedNode?.type)?.fields || {}

  return (
    <div style={{ display: "flex", height: "100%" }}>
      <Palette entries={flow.palette} onAdd={(entry) => send("/steps", "POST", { id: nextId(entry.type), type: entry.type })} />
      <div style={{ flex: 1, position: "relative" }}>
        {error && <div style={{ position: "absolute", zIndex: 5, top: 8, left: 8, padding: "6px 10px", background: "#fee2e2", color: "#991b1b", borderRadius: 6, fontSize: 12 }}>{error}</div>}
        <ReactFlow
          nodes={nodes}
          edges={edges}
          nodeTypes={{ step: StepNode }}
          onNodeClick={(_event, node) => setSelected(node.id)}
          onPaneClick={() => setSelected(null)}
          onConnect={(connection) => send("/edges", "POST", { from: connection.source, to: connection.target, on: connection.sourceHandle })}
          onEdgesDelete={(removed) => removed.forEach((edge) => send("/edges", "DELETE", { from: edge.source, to: edge.target }))}
          onNodesDelete={(removed) => removed.forEach((node) => send(`/steps/${node.id}`, "DELETE"))}
          fitView
        >
          <Background />
          <Controls />
        </ReactFlow>
      </div>
      {selectedNode && (
        <Inspector
          node={selectedNode}
          fields={selectedFields}
          onSave={(config) => send(`/steps/${selectedNode.id}`, "PATCH", { config })}
          onDelete={() => { setSelected(null); send(`/steps/${selectedNode.id}`, "DELETE") }}
        />
      )}
    </div>
  )
}

const start = () =>
  document.querySelectorAll("[data-flow-canvas]").forEach((element) => {
    createRoot(element).render(
      <Canvas base={element.dataset.base} token={element.dataset.csrfToken} initial={JSON.parse(element.dataset.flow)} />
    )
  })

document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", start) : start()
