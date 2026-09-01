import { Controller } from "@hotwired/stimulus"

// Top-right toast: slides in, auto-dismisses after 4s, X closes immediately.
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.itemTargets.forEach((el) => {
      requestAnimationFrame(() => el.classList.add("show"))
      el._toastTimer = setTimeout(() => this.dismiss(el), 4000)
    })
  }

  close(e) { this.dismiss(e.currentTarget.closest(".l-toast")) }

  dismiss(el) {
    if (!el) return
    clearTimeout(el._toastTimer)
    el.classList.remove("show")
    setTimeout(() => {
      el.remove()
      if (this.element.childElementCount === 0) this.element.remove()
    }, 340)
  }
}
