import React from "react"
import { action } from "./styles"
import { phrased, worded } from "./changes"

const panel = { width: 260, padding: 20, overflowY: "auto", background: "#fff", borderLeft: "1px solid #e5e7eb" }
const heading = { fontWeight: 600, marginBottom: 6 }
const quiet = { color: "#6b7280", fontSize: 12, marginBottom: 16 }
const item = { fontSize: 12, marginBottom: 4, lineHeight: 1.4 }

const Panel = ({ changes, problems, refusal, onCut, onPublish }) => (
  <aside style={panel} data-builder-panel>
    <h2 style={heading}>Problems</h2>
    {refusal && <p style={{ ...item, color: "#991b1b", fontWeight: 600 }} data-refusal>Publish refused — see below.</p>}
    {problems.length === 0 && !refusal
      ? <p style={quiet}>Nothing wrong with this flow.</p>
      : <div style={{ marginBottom: 16 }}>
          {problems.map((problem) => (
            <p key={`${problem.node}-${problem.problem}`} style={{ ...item, color: "#b45309" }} data-problem>⚠ {worded(problem)}</p>
          ))}
        </div>}

    <h2 style={heading}>Changes since the last version</h2>
    {changes.length === 0
      ? <p style={quiet}>Nothing has changed.</p>
      : <div style={{ marginBottom: 16 }}>
          {changes.map((change, at) => (
            <p key={at} style={item} data-change>{phrased(change)}</p>
          ))}
        </div>}

    <button style={{ ...action, textAlign: "center" }} onClick={onCut} data-cut-version>Cut version</button>
    <button style={{ ...action, textAlign: "center" }} onClick={onPublish} data-publish>Publish</button>
  </aside>
)

export default Panel
