import React from "react"
import { action } from "./styles"
import { control } from "./Control"
import { worded } from "./changes"
import { standing } from "./flow"

const sheet = { width: 280, padding: 20, overflowY: "auto", background: "#fff", borderLeft: "1px solid #e5e7eb" }
const heading = { fontWeight: 600, marginBottom: 6, marginTop: 14 }
const quiet = { color: "#6b7280", fontSize: 12 }
const item = { fontSize: 12, marginBottom: 4, lineHeight: 1.4 }
const link = { ...action, textAlign: "center", textDecoration: "none", color: "#111827" }

const settling = (flow, name, onSaveDetails) => (event) => {
  if (event.target.value !== (flow[name] ?? "")) onSaveDetails({ [name]: event.target.value })
}

const Panel = ({ flow, changes, problems, refusal, notice, onCreate, onPublish, onSaveDetails, onClose }) => (
  <aside style={sheet} data-builder-panel>
    <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8 }}>
      <h2 style={{ fontWeight: 600 }} data-flow-name>{flow.title || flow.slug}</h2>
      <button title="Close" onClick={onClose}
              style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1, color: "#6b7280" }}>×</button>
    </div>
    <a style={{ ...quiet, display: "block", color: "#2563eb" }} href={flow.history_url} data-history>{standing(flow)}</a>

    <h2 style={heading}>Problems</h2>
    {refusal && <p style={{ ...item, color: "#991b1b", fontWeight: 600 }} data-refusal>{refusal}</p>}
    {notice && !refusal && <p style={{ ...item, color: "#065f46", fontWeight: 600 }} data-notice>{notice}</p>}
    {problems.length === 0 && !refusal
      ? <p style={quiet}>Nothing wrong with this flow.</p>
      : problems.map((problem) => (
          <p key={`${problem.node}-${problem.problem}`} style={{ ...item, color: "#b45309" }} data-problem>⚠ {worded(problem)}</p>
        ))}

    <h2 style={heading}>Changes since the last version</h2>
    {changes.length === 0
      ? <p style={quiet}>Nothing has changed.</p>
      : changes.map((change, at) => <p key={at} style={item} data-change>{change}</p>)}

    <h2 style={heading}>Details</h2>
    <label style={{ display: "block" }}>
      <span style={{ display: "block", marginBottom: 3, color: "#374151" }}>Title</span>
      <input style={control} defaultValue={flow.title ?? ""} onBlur={settling(flow, "title", onSaveDetails)} data-flow-title />
    </label>

    <div style={{ marginTop: 16 }}>
      <button style={{ ...action, textAlign: "center" }} onClick={onCreate} data-create-version>Create version</button>
      <button style={{ ...action, textAlign: "center" }} onClick={onPublish} data-publish>Publish</button>
      <a style={link} href={flow.definition_url} data-definition>Definition</a>
      <a style={link} href={flow.details_url} data-details>Edit details</a>
    </div>
  </aside>
)

export default Panel
