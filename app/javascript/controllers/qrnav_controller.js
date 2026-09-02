import { Controller } from "@hotwired/stimulus"

// Member multi-purpose scanner. Reads a QR (URL or bare token) and navigates to
// the resolve endpoint, which auto-detects promo-claim vs POS-earn.
export default class extends Controller {
  static targets = ["video", "status", "overlay"]
  static values = { resolveUrl: String }

  connect() {
    // Auto-start the camera so users don't tap "Bật camera" every time. If the
    // browser needs a gesture / denies access, start() leaves the overlay button
    // visible as a fallback.
    this.start()
  }

  async start() {
    if (!navigator.mediaDevices?.getUserMedia) {
      this.statusTarget.textContent = "Trình duyệt không hỗ trợ camera — hãy nhập mã bên dưới."
      return
    }
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      this.videoTarget.srcObject = this.stream
      this.videoTarget.setAttribute("playsinline", "true")
      await this.videoTarget.play()
      if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"

      if ("BarcodeDetector" in window) {
        this.mode = "native"
        this.detector = new BarcodeDetector({ formats: ["qr_code"] })
      } else {
        // Fallback for iOS/older browsers: decode frames with jsQR.
        this.mode = "jsqr"
        this.jsqr = (await import("jsqr")).default || window.jsQR
        this.canvas = document.createElement("canvas")
      }
      this.statusTarget.textContent = "Đang quét…"
      this.timer = setInterval(() => this.tick(), this.mode === "jsqr" ? 250 : 400)
    } catch (e) {
      this.statusTarget.textContent = "Không truy cập được camera — hãy nhập mã bên dưới."
    }
  }

  async tick() {
    try {
      if (this.mode === "native") {
        const codes = await this.detector.detect(this.videoTarget)
        if (codes.length) { this.stop(); this.go(codes[0].rawValue) }
      } else {
        const v = this.videoTarget
        if (!v.videoWidth) return
        this.canvas.width = v.videoWidth
        this.canvas.height = v.videoHeight
        const ctx = this.canvas.getContext("2d", { willReadFrequently: true })
        ctx.drawImage(v, 0, 0, this.canvas.width, this.canvas.height)
        const img = ctx.getImageData(0, 0, this.canvas.width, this.canvas.height)
        const res = this.jsqr(img.data, img.width, img.height, { inversionAttempts: "dontInvert" })
        if (res && res.data) { this.stop(); this.go(res.data) }
      }
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
