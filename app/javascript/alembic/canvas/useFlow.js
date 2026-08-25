import { useCallback, useState } from "react"

const useFlow = (base, token, initial) => {
  const [ flow, setFlow ] = useState(initial)
  const [ error, setError ] = useState(null)
  const [ notice, setNotice ] = useState(null)

  const send = useCallback(async (path, method, body) => {
    const response = await fetch(base + path, {
      method, headers: { "Content-Type": "application/json", "X-CSRF-Token": token }, body: body && JSON.stringify(body)
    })
    const answered = await response.json().catch(() => ({}))

    if (!response.ok) {
      setNotice(null)
      return setError(answered.error || "That change was refused")
    }

    setError(null)
    setNotice(answered.notice || null)
    setFlow(await (await fetch(base + ".json", { headers: { Accept: "application/json" } })).json())
  }, [ base, token ])

  return { flow, error, notice, send }
}

export default useFlow
