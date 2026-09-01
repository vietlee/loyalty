import { Controller } from "@hotwired/stimulus"

// Live-updates the customer-app preview card as the merchant edits brand tokens.
export default class extends Controller {
  static targets = ["primary", "primary_2", "surface", "ink", "radius",
                    "fontDisplay", "fontBody", "frame"]

  connect() { this.update() }

  // Reflect the picked hex next to each colour swatch.
  hex(e) {
    const key = e.target.dataset.hexFor
    const span = this.element.querySelector(`[data-hex="${key}"]`)
    if (span) span.textContent = e.target.value
  }

  update() {
    // Also drive the live dashboard chrome (sidebar tint + accents).
    const root = document.documentElement.style
    if (this.hasPrimaryTarget)   root.setProperty("--primary", this.primaryTarget.value)
    if (this.hasPrimary_2Target) root.setProperty("--primary-2", this.primary_2Target.value)

    const f = this.frameTarget.style
    if (this.hasPrimaryTarget)  f.setProperty("--pv-primary", this.primaryTarget.value)
    if (this.hasSurfaceTarget)  f.setProperty("--pv-surface", this.surfaceTarget.value)
    if (this.hasInkTarget)      f.setProperty("--pv-ink", this.inkTarget.value)
    if (this.hasRadiusTarget)   f.setProperty("--pv-radius", `${this.radiusTarget.value}px`)
    if (this.hasFontDisplayTarget) f.setProperty("--pv-fd", `'${this.fontDisplayTarget.value}'`)
    if (this.hasFontBodyTarget)    f.setProperty("--pv-fb", `'${this.fontBodyTarget.value}'`)
  }
}
