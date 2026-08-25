import React, { useMemo, useRef, useState } from "react"
import StepCard from "./StepCard"
import Inspector from "./Inspector"
import TypePicker from "./TypePicker"
import Toolbar from "./Toolbar"
import Panel from "./Panel"
import ConnectorLayer from "./ConnectorLayer"
import useFlow from "./useFlow"
import useConnectors from "./useConnectors"
import { CARD, GAP_X, GAP_Y } from "./styles"
import { nextId } from "./ids"

const page = { display: "flex", height: "100%", minHeight: 0, fontSize: 13, color: "#111827" }
const scroll = { flex: 1, overflow: "auto", position: "relative", background: "#fafafa" }
const grid = { display: "grid", rowGap: GAP_Y, columnGap: 0, padding: 40, justifyContent: "center", position: "relative" }
const notice = { position: "sticky", zIndex: 8, top: 8, margin: "8px auto 0", width: "fit-content", padding: "6px 12px", borderRadius: 6, fontSize: 12 }

const Canvas = ({ base, token, initial }) => {
  const { flow, error, send } = useFlow(base, token, initial)
  const [ selected, setSelected ] = useState(null)
  const [ adding, setAdding ] = useState(null)
  const [ armed, setArmed ] = useState(null)
  const [ dragging, setDragging ] = useState(null)
  const cards = useRef({})
  const surface = useRef(null)

  const byId = useMemo(() => Object.fromEntries(flow.nodes.map((node) => [ node.id, node ])), [ flow.nodes ])
  const { links, extent } = useConnectors(flow, surface, cards, [ flow, selected, byId ])

  const violationsFor = useMemo(() => {
    const grouped = {}
    flow.violations.forEach((violation) => (grouped[violation.node] ||= []).push(violation))
    return grouped
  }, [ flow.violations ])

  const rows = Math.max(0, ...flow.nodes.map((node) => node.row)) + 1
  const columns = Math.max(0, ...flow.nodes.map((node) => node.column)) + 1

  const connectTo = (target) => {
    if (!armed) return

    const [ source, port ] = armed
    setArmed(null)
    if (source !== target) send("/edges", "POST", { from: source, to: target, on: port || null })
  }

  const selectedNode = flow.nodes.find((node) => node.id === selected)
  const entryFor = flow.palette.find((entry) => entry.type === selectedNode?.type)

  return (
    <div style={page} onMouseUp={() => setDragging(null)}
         onKeyDown={(event) => { if (event.key === "Escape") { setSelected(null); setArmed(null); setAdding(null) } }}
         tabIndex={-1}>
      <div ref={surface} style={scroll}
           onClick={(event) => { if (event.target === surface.current) { setSelected(null); setArmed(null) } }}>
        {armed && (
          <div style={{ ...notice, background: "#dbeafe", color: "#1e40af" }}>
            Choose the step “{armed[1] || "next"}” should lead to — <button onClick={() => setArmed(null)} style={{ border: "none", background: "none", color: "#1e40af", textDecoration: "underline", cursor: "pointer", fontSize: 12, padding: 0 }}>cancel</button>
          </div>
        )}
        <Toolbar empty={flow.nodes.length === 0} undoable={flow.undoable} redoable={flow.redoable}
                 onAdd={() => setAdding({ at: { x: 16, y: 52 } })}
                 onUndo={() => { setSelected(null); send("/undo", "POST") }}
                 onRedo={() => { setSelected(null); send("/redo", "POST") }} />

        <ConnectorLayer links={links} extent={extent} dragging={dragging}
                        onInsert={(link) => setAdding({ from: link.source, to: link.target, at: { x: link.midX + 30, y: link.midY } })}
                        onRemove={(link) => { setSelected(null); send("/edges", "DELETE", { from: link.source, to: link.target }) }}
                        onDrop={(link) => { const held = dragging; setDragging(null); send("/steps/" + held + "/move", "PATCH", { from: link.source, to: link.target }) }} />

        <div style={{ ...grid, gridTemplateColumns: `repeat(${columns + 1}, ${(CARD + GAP_X) / 2}px)`, gridTemplateRows: `repeat(${rows}, auto)` }}>
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
                        send("/steps", "POST", { id: nextId(entry.type, flow.nodes.map((node) => node.id)), type: entry.type, from: where.from, to: where.to, on: where.on })
                      }} />
        )}
      </div>

      <Panel changes={flow.changes || []} problems={flow.violations} refusal={error}
             onCut={() => { setSelected(null); send("/versions", "POST") }}
             onPublish={() => { setSelected(null); send("/publish", "POST") }} />

      {selectedNode && (
        <Inspector node={selectedNode}
                   fields={entryFor?.fields || {}} holds={entryFor?.records || {}}
                   labels={entryFor?.labels || {}} recordLabels={entryFor?.record_labels || {}}
                   choices={entryFor?.choices || {}}
                   onClose={() => setSelected(null)}
                   onSave={(config) => send(`/steps/${selectedNode.id}`, "PATCH", { config })}
                   onDelete={() => { setSelected(null); send(`/steps/${selectedNode.id}`, "DELETE") }} />
      )}
    </div>
  )
}

export default Canvas
