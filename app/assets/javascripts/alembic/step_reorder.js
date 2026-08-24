(() => {
  const start = () => {
    const list = document.querySelector("[data-step-list]")
    if (!list) return

    let dragged = null

    const stepIds = () =>
      Array.from(list.querySelectorAll("[data-step-id]")).map((step) => step.dataset.stepId)

    const save = () =>
      fetch(list.dataset.reorderUrl, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": list.dataset.csrfToken },
        body: JSON.stringify({ ids: stepIds() })
      })

    const dropTarget = (event) => {
      const over = event.target.closest("[data-step-id]")
      if (!over || over === dragged) return null

      const box = over.getBoundingClientRect()
      return event.clientY > box.top + box.height / 2 ? over.nextSibling : over
    }

    list.addEventListener("dragstart", (event) => {
      dragged = event.target.closest("[data-step-id]")
      dragged.dataset.dragging = "true"
    })

    list.addEventListener("dragover", (event) => {
      event.preventDefault()
      const target = dropTarget(event)
      if (target !== null) list.insertBefore(dragged, target)
    })

    list.addEventListener("dragend", () => {
      delete dragged.dataset.dragging
      dragged = null
      save()
    })
  }

  document.readyState === "loading"
    ? document.addEventListener("DOMContentLoaded", start)
    : start()
})()
