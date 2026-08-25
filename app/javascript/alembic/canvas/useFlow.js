import { useCallback, useState } from "react"

const useFlow = (base, token, initial) => {
  const [ flow, setFlow ] = useState(initial)
  const [ error, setError ] = useState(null)

  const send = useCallback(async (path, method, body) => {
    const response = await fetch(base + path, {
      method, headers: { "Content-Type": "application/json", "X-CSRF-Token": token }, body: body && JSON.stringify(body)
    })
    if (!response.ok) return setError((await response.json().catch(() => ({}))).error || "That change was refused")

    setError(null)
    setFlow(await (await fetch(base + ".json", { headers: { Accept: "application/json" } })).json())
  }, [ base, token ])

  return { flow, error, send }
}

export default useFlow
