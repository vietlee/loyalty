import { Controller } from "@hotwired/stimulus"

// Adds pagination dots under a horizontal scroll track so users know they can
// scroll for more. Dots ≈ number of viewport-pages; click a dot to jump.
export default class extends Controller {
  static targets = ["track", "dots"]

  connect() {
    this.onScroll = () => this.update()
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })
    this.render()
    this.resizeObserver = new ResizeObserver(() => this.render())
    this.resizeObserver.observe(this.trackTarget)
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
    this.resizeObserver?.disconnect()
  }

  pages() {
    const w = this.trackTarget.clientWidth
    if (!w) return 1
    // Any horizontal overflow (>4px) means there is more to scroll → show dots.
    return this.trackTarget.scrollWidth - w > 4 ? Math.ceil(this.trackTarget.scrollWidth / w) : 1
  }

  render() {
    const n = this.pages()
    if (n <= 1) { this.dotsTarget.style.display = "none"; this.dotsTarget.innerHTML = ""; return }
    this.dotsTarget.style.display = "flex"
    this.dotsTarget.innerHTML = ""
    for (let i = 0; i < n; i++) {
      const d = document.createElement("button")
      d.className = "l-dot"
      d.type = "button"
      d.addEventListener("click", () => this.go(i))
      this.dotsTarget.appendChild(d)
    }
    this.update()
  }

  go(i) {
    this.trackTarget.scrollTo({ left: i * this.trackTarget.clientWidth, behavior: "smooth" })
  }

  update() {
    const i = Math.round(this.trackTarget.scrollLeft / this.trackTarget.clientWidth)
    Array.from(this.dotsTarget.children).forEach((d, j) => d.classList.toggle("active", j === i))
  }
}
