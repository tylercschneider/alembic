import React from "react"
import { action } from "./styles"
import { phrased, worded } from "./changes"
import { standing } from "./flow"

const sheet = {
  position: "absolute", top: 56, left: 16, zIndex: 7, width: 300, maxHeight: "calc(100% - 80px)",
  overflowY: "auto", padding: 16, background: "#fff", border: "1px solid #e5e7eb",
  borderRadius: 8, boxShadow: "0 6px 20px rgba(0,0,0,.15)"
}
const heading = { fontWeight: 600, marginBottom: 6, marginTop: 14 }
const quiet = { color: "#6b7280", fontSize: 12 }
const item = { fontSize: 12, marginBottom: 4, lineHeight: 1.4 }
const link = { ...action, textAlign: "center", textDecoration: "none", color: "#111827" }

const Panel = ({ flow, changes, problems, refusal, onCreate, onPublish, onClose }) => (
  <div style={sheet} data-builder-panel>
    <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8 }}>
      <h2 style={{ fontWeight: 600 }}>{flow.title}</h2>
      <button title="Close" onClick={onClose}
              style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1, color: "#6b7280" }}>×</button>
    </div>
    <p style={quiet} data-versions>{standing(flow)}</p>

    <h2 style={heading}>Problems</h2>
    {refusal && <p style={{ ...item, color: "#991b1b", fontWeight: 600 }} data-refusal>Publish refused — see below.</p>}
    {problems.length === 0 && !refusal
      ? <p style={quiet}>Nothing wrong with this flow.</p>
      : problems.map((problem) => (
          <p key={`${problem.node}-${problem.problem}`} style={{ ...item, color: "#b45309" }} data-problem>⚠ {worded(problem)}</p>
        ))}

    <h2 style={heading}>Changes since the last version</h2>
    {changes.length === 0
      ? <p style={quiet}>Nothing has changed.</p>
      : changes.map((change, at) => <p key={at} style={item} data-change>{phrased(change)}</p>)}

    <div style={{ marginTop: 16 }}>
      <button style={{ ...action, textAlign: "center" }} onClick={onCreate} data-create-version>Create version</button>
      <button style={{ ...action, textAlign: "center" }} onClick={onPublish} data-publish>Publish</button>
      <a style={link} href={flow.definition_url} data-definition>Definition</a>
      <a style={link} href={flow.details_url} data-details>Edit details</a>
    </div>
  </div>
)

export default Panel
