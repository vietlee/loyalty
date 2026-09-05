import { Controller } from "@hotwired/stimulus"

// Generic tab group. Remembers the active tab in localStorage (keyed by
// data-tabs-key-value) so a refresh — or a form POST that redirects back —
// stays on the same tab.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { key: String, default: String }

  connect() {
    const initial = this.load() || this.defaultValue || this.tabTargets[0]?.dataset.tab
    if (initial) this.activate(initial)
  }

  select(e) { this.activate(e.currentTarget.dataset.tab) }

  activate(name) {
    let matched = false
    this.tabTargets.forEach((t) => {
      const on = t.dataset.tab === name
      matched = matched || on
      t.classList.toggle("l-chip-brand", on)
    })
    if (!matched) name = this.tabTargets[0]?.dataset.tab
    this.panelTargets.forEach((p) => { p.hidden = p.dataset.tab !== name })
    this.save(name)
  }

  save(n) { try { localStorage.setItem(this.storageKey, n) } catch (e) {} }
  load()  { try { return localStorage.getItem(this.storageKey) } catch (e) { return null } }
  get storageKey() { return `tabs:${this.keyValue || this.element.id || "default"}` }
}
