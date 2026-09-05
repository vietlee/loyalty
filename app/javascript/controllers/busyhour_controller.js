import { Controller } from "@hotwired/stimulus"

// Busy-hour panel: switch branch (GET) and refresh the AI suggestion (POST)
// over AJAX — no page reload. Also shows a hover tooltip with the real purchase
// count for each heatmap cell.
export default class extends Controller {
  static targets = ["panel", "outlet", "refreshBtn"]
  static values = { url: String, refreshUrl: String, range: String }

  connect() { this.bindTooltip() }

  outlet() { return this.hasOutletTarget ? this.outletTarget.value : "" }

  // Branch <select> change → reload the panel for that branch.
  async switch() {
    const qs = new URLSearchParams({ outlet: this.outlet(), range: this.rangeValue })
    await this.swap(() => fetch(`${this.urlValue}?${qs}`, { headers: { "Accept": "text/html" } }))
  }

  // Refresh button → (re)generate the AI insight for the current branch.
  async refresh() {
    const outlet = this.outlet()
    if (this.hasRefreshBtnTarget) {
      this.refreshBtnTarget.disabled = true
      this.refreshBtnTarget.textContent = "⏳ Đang tạo gợi ý…"
    }
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const qs = new URLSearchParams({ outlet, range: this.rangeValue })
    await this.swap(() => fetch(`${this.refreshUrlValue}?${qs}`, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "text/html" }
    }))
  }

  async swap(request) {
    try {
      const resp = await request()
      if (!resp.ok) throw new Error(resp.status)
      this.panelTarget.innerHTML = await resp.text()
      this.bindTooltip()
    } catch (e) {
      if (this.hasRefreshBtnTarget) {
        this.refreshBtnTarget.disabled = false
        this.refreshBtnTarget.textContent = "🔄 Làm mới gợi ý"
      }
      // leave the existing panel in place on error
    }
  }

  // Lightweight hover tooltip showing the real purchase count per cell.
  bindTooltip() {
    const cells = this.panelTarget.querySelectorAll("rect[data-count]")
    cells.forEach((cell) => {
      cell.addEventListener("mouseenter", (e) => this.showTip(e, cell))
      cell.addEventListener("mousemove", (e) => this.moveTip(e))
      cell.addEventListener("mouseleave", () => this.hideTip())
    })
  }

  tip() {
    if (!this._tip) {
      this._tip = document.createElement("div")
      this._tip.style.cssText = "position:fixed;z-index:9999;pointer-events:none;background:#2A211C;color:#fff;padding:6px 10px;border-radius:8px;font-size:12px;font-weight:600;white-space:nowrap;box-shadow:0 4px 14px rgba(0,0,0,.25);opacity:0;transition:opacity .1s;"
      document.body.appendChild(this._tip)
    }
    return this._tip
  }

  showTip(e, cell) {
    const t = this.tip()
    t.textContent = `${cell.dataset.slot} · ${cell.dataset.count} lượt mua`
    t.style.opacity = "1"
    this.moveTip(e)
  }

  moveTip(e) {
    const t = this.tip()
    t.style.left = `${e.clientX + 12}px`
    t.style.top = `${e.clientY - 34}px`
  }

  hideTip() { if (this._tip) this._tip.style.opacity = "0" }

  disconnect() { if (this._tip) { this._tip.remove(); this._tip = null } }
}
