const PHRASING = {
  added: "Added",
  updated: "Updated",
  removed: "Removed",
  moved: "Moved",
  connected: "Connected",
  disconnected: "Disconnected"
}

export const phrased = (change) => {
  const named = (change.named || []).filter(Boolean).map((name) => `“${name}”`)
  const verb = PHRASING[change.action] || change.action

  return named.length ? `${verb} ${named.join(" → ")}` : verb
}

export const worded = (violation) => {
  const problem = violation.problem.replace(/_/g, " ")

  return violation.node ? `“${violation.node}” ${problem}` : problem
}
