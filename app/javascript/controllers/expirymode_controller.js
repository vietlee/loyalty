import { Controller } from "@hotwired/stimulus"

// Voucher validity mode: enable only the input for the chosen option (N days
// after claim vs a fixed expiry date). Disabled inputs aren't submitted, so the
// controller reads exactly one, unambiguously.
export default class extends Controller {
  static targets = ["radio", "relativeInput", "fixedInput"]

  connect() { this.apply() }
  switch() { this.apply() }

  apply() {
    const mode = this.radioTargets.find((r) => r.checked)?.value || "relative"
    if (this.hasRelativeInputTarget) this.relativeInputTarget.disabled = mode !== "relative"
    if (this.hasFixedInputTarget) this.fixedInputTarget.disabled = mode !== "fixed"
  }
}
