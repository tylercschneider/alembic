import React from "react"
import { createRoot } from "react-dom/client"
import Canvas from "./canvas/Canvas"

const start = () =>
  document.querySelectorAll("[data-flow-canvas]").forEach((element) => {
    createRoot(element).render(
      <Canvas base={element.dataset.base} token={element.dataset.csrfToken} initial={JSON.parse(element.dataset.flow)} />
    )
  })

document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", start) : start()
