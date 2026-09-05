import { Controller } from "@hotwired/stimulus"

// Social share helpers for the social_share mission. `native` opens the device
// share sheet (mobile) — the fastest way to post to any app; `copy` copies the
// shop link so the customer can paste it into a network the sheet doesn't cover.
export default class extends Controller {
  static targets = ["copyLabel"]
  static values = { url: String, text: String }

  async native() {
    const data = { title: this.textValue, text: this.textValue, url: this.urlValue }
    if (navigator.share) {
      try { await navigator.share(data) } catch (e) { /* user cancelled */ }
    } else {
      this.copy()
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      if (this.hasCopyLabelTarget) {
        const el = this.copyLabelTarget, prev = el.textContent
        el.textContent = "✓ Đã copy"
        setTimeout(() => { el.textContent = prev }, 1600)
      }
    } catch (e) {
      window.prompt("Sao chép link:", this.urlValue)
    }
  }
}
