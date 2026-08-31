import { Controller } from "@hotwired/stimulus"

// Web Share API with clipboard fallback for the referral link.
export default class extends Controller {
  static targets = ["copyBtn"]
  static values = { url: String, text: String }

  async native() {
    if (navigator.share) {
      try { await navigator.share({ title: document.title, text: this.textValue, url: this.urlValue }) } catch (e) {}
    } else {
      this.copy()
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      if (this.hasCopyBtnTarget) {
        const t = this.copyBtnTarget.textContent
        this.copyBtnTarget.textContent = "✓ Đã sao chép"
        setTimeout(() => (this.copyBtnTarget.textContent = t), 1600)
      }
    } catch (e) {
      prompt("Sao chép link:", this.urlValue)
    }
  }
}
