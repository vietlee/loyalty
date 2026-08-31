import { Controller } from "@hotwired/stimulus"

// Simple client-side tab switcher: buttons [data-name] toggle panels [data-name].
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String }

  connect() { this.show(this.activeValue || this.tabTargets[0]?.dataset.name) }

  select(e) { this.show(e.currentTarget.dataset.name) }

  show(name) {
    this.tabTargets.forEach((t) => t.classList.toggle("active", t.dataset.name === name))
    this.panelTargets.forEach((p) => (p.hidden = p.dataset.name !== name))
  }
}
