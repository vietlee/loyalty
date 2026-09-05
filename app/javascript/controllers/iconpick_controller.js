import { Controller } from "@hotwired/stimulus"

// Quick emoji picker: click a suggested emoji to fill the icon input.
export default class extends Controller {
  static targets = ["input"]

  pick(event) {
    event.preventDefault()
    if (!this.hasInputTarget) return
    this.inputTarget.value = event.currentTarget.dataset.emoji
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
