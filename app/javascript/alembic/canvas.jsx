import React, { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react"
import { createRoot } from "react-dom/client"

const CARD = 240
const GAP_X = 40
const GAP_Y = 64

const S = {
  page: { display: "flex", height: "100%", minHeight: 0, fontSize: 13, color: "#111827" },
  scroll: { flex: 1, overflow: "auto", position: "relative", background: "#fafafa" },
  grid: { display: "grid", rowGap: GAP_Y, columnGap: 0, padding: 40, justifyContent: "center", position: "relative" },
  card: { width: CARD, boxSizing: "border-box", padding: "12px 14px", background: "#fff", borderRadius: 8, cursor: "grab" },
  panel: { width: 280, padding: 20, overflowY: "auto", background: "#fff", borderLeft: "1px solid #e5e7eb" },
  control: { width: "100%", marginBottom: 12, padding: "6px 8px", border: "1px solid #d1d5db", borderRadius: 4, fontSize: 13, boxSizing: "border-box" },
  action: { display: "block", width: "100%", marginBottom: 6, padding: "7px 10px", textAlign: "left", cursor: "pointer", border: "1px solid #d1d5db", borderRadius: 6, background: "#fff", fontSize: 13 },
  plus: { width: 24, height: 24, borderRadius: "50%", border: "1px solid #d1d5db", background: "#fff", cursor: "pointer", fontSize: 15, lineHeight: "15px", color: "#374151" }
}

const Port = ({ name, connected, armed, onArm, connecting }) => (
  <button onClick={(event) => { if (connecting) return; event.stopPropagation(); onArm(event) }}
          title={armed ? "Now choose a step to connect to" : "Connect this branch"}
          style={{
            padding: "1px 8px", marginRight: 4, borderRadius: 999, fontSize: 11, cursor: "pointer",
            border: `1px solid ${armed ? "#2563eb" : connected ? "#d1d5db" : "#f59e0b"}`,
            background: armed ? "#2563eb" : "#fff", color: armed ? "#fff" : connected ? "#6b7280" : "#b45309"
          }}>{name || "next"}</button>
)

const StepCard = ({ node, selected, armed, connecting, onSelect, onArm, onDragEnd, onDragStart }) => (
  <div ref={node.ref}
       data-step={node.id}
       draggable
       onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
       onDragEnd={onDragEnd}
       onClick={onSelect}
       style={{
         ...S.card,
         cursor: connecting ? "crosshair" : "grab",
         border: `2px solid ${connecting ? "#2563eb" : node.violations.length ? "#dc2626" : selected ? "#2563eb" : "#d1d5db"}`,
         boxShadow: selected ? "0 0 0 3px rgba(37,99,235,.15)" : "0 1px 2px rgba(0,0,0,.05)"
       }}>
    <div style={{ fontWeight: 600, lineHeight: 1.3 }}>{node.label}</div>
    <div style={{ color: "#6b7280", fontSize: 11, marginTop: 2 }}>{node.type}</div>
    {node.violations.map((violation) => (
      <div key={violation.problem + violation.detail} style={{ color: "#dc2626", fontSize: 11, marginTop: 6 }}>
        {violation.problem.replace(/_/g, " ")}{violation.detail ? `: ${violation.detail}` : ""}
      </div>
    ))}
    <div style={{ marginTop: 10 }}>
      {(node.ports.length ? node.ports : [ null ]).map((port) => (
        <Port key={port || "next"} name={port} connected={node.connected.includes(port)}
              connecting={connecting} armed={armed === (port || "")} onArm={(event) => onArm(port || "", event)} />
      ))}
    </div>
  </div>
)

const Control = ({ type, value, choices, onChange, onSettle }) => {
  if (type === "boolean") return <input type="checkbox" checked={Boolean(value)} onChange={(e) => onSettle(e.target.checked)} />
  if (type === "select") {
    return <select style={S.control} value={value ?? ""} onChange={(e) => onSettle(e.target.value)}>
      <option value=""></option>
      {(choices || []).map((choice) => <option key={choice} value={choice}>{choice}</option>)}
    </select>
  }
  if (type === "multi_select") {
    const chosen = Array.isArray(value) ? value : []
    const toggle = (choice) => onSettle(chosen.includes(choice) ? chosen.filter((c) => c !== choice) : [ ...chosen, choice ])
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
    return <input style={S.control} type="number" step={type === "integer" ? "1" : "any"} value={value ?? ""}
                  onChange={(e) => onChange(e.target.value)} onBlur={(e) => onSettle(e.target.value)} />
  }

  return <input style={S.control} type="text" value={value ?? ""}
                onChange={(e) => onChange(e.target.value)} onBlur={(e) => onSettle(e.target.value)} />
}

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
          <button style={{ ...S.action, textAlign: "center", fontSize: 11, padding: "3px 8px" }}
                  onClick={() => onSettle(kept.filter((_, at) => at !== index))}>Remove</button>
        </div>
      ))}
      <button style={{ ...S.action, textAlign: "center" }} onClick={() => onSettle([ ...kept, {} ])}>Add</button>
    </div>
  )
}

const Inspector = ({ node, fields, holds, labels, recordLabels, choices, onSave, onDelete, onClose }) => {
  const [ draft, setDraft ] = useState(node.config)
  useEffect(() => setDraft(node.config), [ node.id, node.config ])

  const settle = (next) => {
    setDraft(next)
    if (JSON.stringify(next) !== JSON.stringify(node.config)) onSave(next)
  }

  return (
    <aside style={S.panel}>
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
      <button style={{ ...S.action, textAlign: "center", color: "#dc2626" }} onClick={onDelete}>Delete step</button>
    </aside>
  )
}

const TypePicker = ({ entries, at, onPick, onConnect, onDismiss }) => (
  <div style={{ position: "absolute", zIndex: 9, top: at.y, left: at.x, width: 210, padding: 8, background: "#fff", border: "1px solid #e5e7eb", borderRadius: 8, boxShadow: "0 6px 20px rgba(0,0,0,.15)" }}>
    <p style={{ margin: "0 0 6px", fontSize: 11, color: "#6b7280" }}>Add a step</p>
    {entries.map((entry) => (
      <button key={entry.type} style={S.action} onClick={() => onPick(entry)}>
        {entry.label}
        <span style={{ display: "block", color: "#6b7280", fontSize: 11 }}>{entry.type}</span>
      </button>
    ))}
    {onConnect && (
      <button style={{ ...S.action, textAlign: "center" }} onClick={onConnect}>Connect to a step already here</button>
    )}
    <button style={{ ...S.action, textAlign: "center", marginBottom: 0 }} onClick={onDismiss}>Cancel</button>
  </div>
)

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
      <div style={{ display: "flex", gap: 4, justifyContent: "center", alignItems: "center", height: "100%",
                    opacity: showing ? 1 : 0, transition: "opacity .12s" }}>
        <button title={dragging ? "Move the step here" : "Insert a step here"} onClick={onInsert}
                style={{ ...S.plus, borderColor: dragging && over ? "#2563eb" : "#d1d5db" }}>+</button>
        {!dragging && (
          <button title="Remove this connection" onClick={onRemove}
                  style={{ ...S.plus, color: "#dc2626", borderColor: "#e5b4b4" }}>×</button>
        )}
      </div>
    </div>
  )
}

const Canvas = ({ base, token, initial }) => {
  const [ flow, setFlow ] = useState(initial)
  const [ selected, setSelected ] = useState(null)
  const [ error, setError ] = useState(null)
  const [ adding, setAdding ] = useState(null)
  const [ armed, setArmed ] = useState(null)
  const [ dragging, setDragging ] = useState(null)
  const [ links, setLinks ] = useState([])
  const [ extent, setExtent ] = useState({ width: "100%", height: "100%" })
  const cards = useRef({})
  const surface = useRef(null)

  const send = useCallback(async (path, method, body) => {
    const response = await fetch(base + path, {
      method, headers: { "Content-Type": "application/json", "X-CSRF-Token": token }, body: body && JSON.stringify(body)
    })
    if (!response.ok) return setError((await response.json().catch(() => ({}))).error || "That change was refused")

    setError(null)
    setFlow(await (await fetch(base + ".json", { headers: { Accept: "application/json" } })).json())
  }, [ base, token ])

  const byId = useMemo(() => Object.fromEntries(flow.nodes.map((node) => [ node.id, node ])), [ flow.nodes ])

  const violationsFor = useMemo(() => {
    const grouped = {}
    flow.violations.forEach((violation) => (grouped[violation.node] ||= []).push(violation))
    return grouped
  }, [ flow.violations ])

  useLayoutEffect(() => {
    const measure = () => {
      const frame = surface.current?.getBoundingClientRect()
      if (!frame) return

      setExtent({ width: surface.current.scrollWidth, height: surface.current.scrollHeight })

      const anchor = (box, side) => {
        const l = box.left - frame.left + surface.current.scrollLeft
        const t = box.top - frame.top + surface.current.scrollTop

        if (side === "left") return { x: l, y: t + box.height / 2 }
        if (side === "right") return { x: l + box.width, y: t + box.height / 2 }
        if (side === "top") return { x: l + box.width / 2, y: t }
        return { x: l + box.width / 2, y: t + box.height }
      }

      const shy = (point, side) => {
        if (side === "top") return { x: point.x, y: point.y - 3 }
        if (side === "left") return { x: point.x - 3, y: point.y }
        if (side === "right") return { x: point.x + 3, y: point.y }
        return { x: point.x, y: point.y + 3 }
      }

      setLinks(flow.edges.flatMap((edge) => {
        const fromBox = cards.current[edge.source]?.getBoundingClientRect()
        const toBox = cards.current[edge.target]?.getBoundingClientRect()
        if (!fromBox || !toBox) return []

        const a = anchor(fromBox, edge.leaves)
        const b = shy(anchor(toBox, edge.enters), edge.enters)
        const lane = (anchor(fromBox, "bottom").y + anchor(toBox, "top").y) / 2
        const detour = edge.leaves === "left" ? Math.min(a.x, b.x) - 28 : Math.max(a.x, b.x) + 28

        const path = {
          straight: `M ${a.x} ${a.y} L ${b.x} ${b.y}`,
          turn: `M ${a.x} ${a.y} H ${b.x} V ${b.y}`,
          lane: `M ${a.x} ${a.y} V ${lane} H ${b.x} V ${b.y}`,
          detour: `M ${a.x} ${a.y} H ${detour} V ${b.y} H ${b.x}`
        }[edge.route]

        const midX = edge.route === "detour" ? detour : (a.x + b.x) / 2
        const midY = edge.route === "lane" ? lane : (a.y + b.y) / 2

        return [ { ...edge, path, midX, midY } ]
      }))
    }

    measure()
    window.addEventListener("resize", measure)

    const watcher = new ResizeObserver(measure)
    if (surface.current) watcher.observe(surface.current)

    return () => {
      window.removeEventListener("resize", measure)
      watcher.disconnect()
    }
  }, [ flow, selected, byId ])

  const rows = Math.max(0, ...flow.nodes.map((node) => node.row)) + 1
  const columns = Math.max(0, ...flow.nodes.map((node) => node.column)) + 1

  const nextId = (type) => {
    const taken = new Set(flow.nodes.map((node) => node.id))
    let candidate = type
    let suffix = 2
    while (taken.has(candidate)) candidate = `${type}_${suffix++}`
    return candidate
  }

  const connectTo = (target) => {
    if (!armed) return

    const [ source, port ] = armed
    setArmed(null)
    if (source !== target) send("/edges", "POST", { from: source, to: target, on: port || null })
  }

  const selectedNode = flow.nodes.find((node) => node.id === selected)
  const entryFor = flow.palette.find((entry) => entry.type === selectedNode?.type)
  const fieldsFor = entryFor?.fields || {}
  const holdsFor = entryFor?.records || {}
  const labelsFor = entryFor?.labels || {}
  const recordLabelsFor = entryFor?.record_labels || {}
  const choicesFor = entryFor?.choices || {}

  return (
    <div style={S.page} onMouseUp={() => setDragging(null)}
         onKeyDown={(event) => { if (event.key === "Escape") { setSelected(null); setArmed(null); setAdding(null) } }}
         tabIndex={-1}>
      <div ref={surface} style={S.scroll}
           onClick={(event) => { if (event.target === surface.current) { setSelected(null); setArmed(null) } }}>
        {error && <div style={{ position: "sticky", zIndex: 8, top: 8, margin: "8px auto 0", width: "fit-content", padding: "6px 12px", background: "#fee2e2", color: "#991b1b", borderRadius: 6, fontSize: 12 }}>{error}</div>}
        {armed && !error && (
          <div style={{ position: "sticky", zIndex: 8, top: 8, margin: "8px auto 0", width: "fit-content", padding: "6px 12px", background: "#dbeafe", color: "#1e40af", borderRadius: 6, fontSize: 12 }}>
            Choose the step “{armed[1] || "next"}” should lead to — <button onClick={() => setArmed(null)} style={{ border: "none", background: "none", color: "#1e40af", textDecoration: "underline", cursor: "pointer", fontSize: 12, padding: 0 }}>cancel</button>
          </div>
        )}
        <div style={{ position: "absolute", top: 16, left: 16, zIndex: 5, display: "flex", gap: 8 }}>
          {flow.nodes.length === 0 && (
            <button style={S.plus} title="Add a step" onClick={() => setAdding({ at: { x: 16, y: 52 } })}>+</button>
          )}
          <button title={flow.undoable ? "Undo the last change" : "Nothing to undo"}
                  disabled={!flow.undoable}
                  onClick={() => { setSelected(null); send("/undo", "POST") }}
                  style={{ ...S.action, width: "auto", marginBottom: 0, padding: "5px 12px",
                           opacity: flow.undoable ? 1 : 0.4, cursor: flow.undoable ? "pointer" : "default" }}>↶ Undo</button>
          <button title={flow.redoable ? "Redo the change you undid" : "Nothing to redo"}
                  disabled={!flow.redoable}
                  onClick={() => { setSelected(null); send("/redo", "POST") }}
                  style={{ ...S.action, width: "auto", marginBottom: 0, padding: "5px 12px",
                           opacity: flow.redoable ? 1 : 0.4, cursor: flow.redoable ? "pointer" : "default" }}>↷ Redo</button>
        </div>

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
          <div key={`${link.id}-label`} style={{ position: "absolute", left: link.midX - 10, top: link.midY - 18, zIndex: 3, fontSize: 11, color: "#6b7280", background: "#fafafa", padding: "0 3px" }}>{link.label}</div>
        ))}

        {links.map((link) => (
          <Connector key={link.id} link={link} dragging={Boolean(dragging)}
                     onInsert={() => setAdding({ from: link.source, to: link.target, at: { x: link.midX + 30, y: link.midY } })}
                     onRemove={() => { setSelected(null); send("/edges", "DELETE", { from: link.source, to: link.target }) }}
                     onDrop={() => { const held = dragging; setDragging(null); send("/steps/" + held + "/move", "PATCH", { from: link.source, to: link.target }) }} />
        ))}

        <div style={{ ...S.grid, gridTemplateColumns: `repeat(${columns + 1}, ${(CARD + GAP_X) / 2}px)`, gridTemplateRows: `repeat(${rows}, auto)` }}>
          {flow.nodes.map((node) => (
            <div key={node.id} style={{ gridRow: node.row + 1, gridColumn: `${node.column + 1} / span 2`, zIndex: 2 }}>
              <StepCard
                node={{
                  ...node,
                  ref: (element) => { cards.current[node.id] = element },
                  violations: violationsFor[node.id] || [],
                  connected: flow.edges.filter((edge) => edge.source === node.id).map((edge) => edge.label || null)
                }}
                selected={node.id === selected}
                armed={armed && armed[0] === node.id ? armed[1] : null}
                connecting={Boolean(armed) && armed[0] !== node.id}
                onSelect={() => (armed ? connectTo(node.id) : setSelected(node.id))}
                onArm={(port, event) => {
                  const frame = surface.current.getBoundingClientRect()
                  setAdding({
                    from: node.id, on: port,
                    at: { x: event.clientX - frame.left + surface.current.scrollLeft + 8,
                          y: event.clientY - frame.top + surface.current.scrollTop + 8 }
                  })
                }}
                onDragEnd={() => setDragging(null)}
                onDragStart={() => setDragging(node.id)}
              />
            </div>
          ))}
        </div>

        {adding && (
          <TypePicker entries={flow.palette} at={adding.at} onDismiss={() => setAdding(null)}
                      onConnect={adding.on !== undefined ? () => { setArmed([ adding.from, adding.on ]); setAdding(null) } : null}
                      onPick={(entry) => {
                        const where = adding
                        setAdding(null)
                        send("/steps", "POST", { id: nextId(entry.type), type: entry.type, from: where.from, to: where.to, on: where.on })
                      }} />
        )}
      </div>

      {selectedNode && (
        <Inspector node={selectedNode} fields={fieldsFor} holds={holdsFor} labels={labelsFor} recordLabels={recordLabelsFor} choices={choicesFor} onClose={() => setSelected(null)}
                   onSave={(config) => send(`/steps/${selectedNode.id}`, "PATCH", { config })}
                   onDelete={() => { setSelected(null); send(`/steps/${selectedNode.id}`, "DELETE") }} />
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
