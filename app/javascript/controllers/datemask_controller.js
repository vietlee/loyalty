import { Controller } from "@hotwired/stimulus"

// Formats a birthday field as DD/MM/YYYY as the user types (digits only),
// independent of browser/OS locale.
export default class extends Controller {
  format() {
    const d = this.element.value.replace(/\D/g, "").slice(0, 8)
    let out = d.slice(0, 2)
    if (d.length > 2) out += "/" + d.slice(2, 4)
    if (d.length > 4) out += "/" + d.slice(4, 8)
    this.element.value = out
  }
}
