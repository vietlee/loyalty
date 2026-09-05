import { Controller } from "@hotwired/stimulus"

// Voucher validity mode: enable only the input for the chosen option (N days
// after claim vs a fixed expiry date). Disabled inputs aren't submitted, so the
// controller reads exactly one, unambiguously.
export default class extends Controller {
  static targets = ["radio", "relativeInput", "fixedInput", "relativeRow", "fixedRow"]

  connect() { this.apply() }
  switch() { this.apply() }

  apply() {
    const mode = this.radioTargets.find((r) => r.checked)?.value || "relative"
    if (this.hasRelativeInputTarget) this.relativeInputTarget.disabled = mode !== "relative"
    if (this.hasFixedInputTarget) this.fixedInputTarget.disabled = mode !== "fixed"
    if (this.hasRelativeRowTarget) this.dim(this.relativeRowTarget, mode !== "relative")
    if (this.hasFixedRowTarget) this.dim(this.fixedRowTarget, mode !== "fixed")
  }

  // Grey out the row that isn't selected (but keep its radio clickable to switch).
  dim(row, off) {
    if (!row) return
    row.style.opacity = off ? "0.4" : "1"
    row.querySelectorAll("input:not([type=radio]), select").forEach((el) => {
      el.style.pointerEvents = off ? "none" : ""
    })
  }
}
