import { Controller } from "@hotwired/stimulus"

// Keeps the active nav item visible: after each (Turbo) navigation the sidebar
// re-renders at scrollTop 0, which can hide a lower active item. On connect we
// scroll ONLY the sidebar so the active item is centred — no page jump.
export default class extends Controller {
  connect() {
    const active = this.element.querySelector(".l-nav-item.active")
    if (!active) return
    const c = this.element
    const r = active.getBoundingClientRect()
    const cr = c.getBoundingClientRect()
    // if already comfortably in view, leave it
    if (r.top >= cr.top + 8 && r.bottom <= cr.bottom - 8) return
    c.scrollTop += (r.top - cr.top) - (c.clientHeight - r.height) / 2
  }
}
