import { Controller } from "@hotwired/stimulus"

// Member multi-purpose scanner. Reads a QR (URL or bare token) and navigates to
// the resolve endpoint, which auto-detects promo-claim vs POS-earn.
export default class extends Controller {
  static targets = ["video", "status", "overlay"]
  static values = { resolveUrl: String }

  async start() {
    if (!("BarcodeDetector" in window)) {
      this.statusTarget.textContent = "Trình duyệt không hỗ trợ quét — hãy nhập mã bên dưới."
      return
    }
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      this.videoTarget.srcObject = this.stream
      await this.videoTarget.play()
      if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
      this.detector = new BarcodeDetector({ formats: ["qr_code"] })
      this.statusTarget.textContent = "Đang quét…"
      this.timer = setInterval(() => this.tick(), 400)
    } catch (e) {
      this.statusTarget.textContent = "Không truy cập được camera — hãy nhập mã bên dưới."
    }
  }

  async tick() {
    try {
      const codes = await this.detector.detect(this.videoTarget)
      if (codes.length) { this.stop(); this.go(codes[0].rawValue) }
    } catch (e) { /* transient */ }
  }

  go(value) {
    try {
      const u = new URL(value)
      if (u.origin === location.origin) { window.location.href = value; return }
    } catch (e) { /* not a URL */ }
    window.location.href = `${this.resolveUrlValue}?code=${encodeURIComponent(value)}`
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    if (this.stream) this.stream.getTracks().forEach((t) => t.stop())
  }

  disconnect() { this.stop() }
}
