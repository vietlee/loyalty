import { Controller } from "@hotwired/stimulus"

// Lucky wheel: POSTs a spin, then rotates the SVG so the winning segment lands
// under the pointer and reveals the prize with confetti.
export default class extends Controller {
  static targets = ["wheel", "btn", "result", "hint"]
  static values = { spinUrl: String, count: Number, cost: Number }

  connect() { this.rotation = 0; this.spinning = false }

  async spin() {
    if (this.spinning) return
    this.spinning = true
    this.btnTarget.disabled = true
    this.resultTarget.textContent = ""

    let data
    try {
      const res = await fetch(this.spinUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content, Accept: "application/json" }
      })
      data = await res.json()
      if (data.error) { this.fail(data.error); return }
    } catch (e) { this.fail("Có lỗi, thử lại sau."); return }

    const n = this.countValue
    const ang = 360 / n
    // Bring the winning segment's center to the top pointer, plus 5 full turns.
    const target = 360 * 6 - (data.index * ang + ang / 2)
    this.rotation += target
    this.wheelTarget.style.transform = `rotate(${this.rotation}deg)`

    setTimeout(() => this.reveal(data), 4100)
  }

  reveal(data) {
    this.resultTarget.textContent = data.points > 0 ? `🎉 ${data.label}!` : `${data.label} — chúc bạn may mắn lần sau`
    if (data.points > 0) this.confetti()
    // Update spin state
    if (data.free_left) {
      this.btnTarget.textContent = "Quay miễn phí 🎉"
      this.hintTarget.textContent = "Bạn còn lượt quay miễn phí."
    } else {
      this.btnTarget.textContent = `Quay (${this.costValue} điểm)`
      this.hintTarget.textContent = `Số dư: ${data.balance.toLocaleString("vi-VN")} điểm.`
    }
    this.btnTarget.disabled = false
    this.spinning = false
  }

  fail(msg) {
    this.resultTarget.textContent = msg
    this.btnTarget.disabled = false
    this.spinning = false
  }

  confetti() {
    const el = document.createElement("div")
    el.dataset.controller = "pointburst"
    document.body.appendChild(el)
    setTimeout(() => el.remove(), 2000)
  }
}
