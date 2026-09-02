import { Controller } from "@hotwired/stimulus"

// Member multi-purpose scanner. Reads a QR (URL or bare token) and navigates to
// the resolve endpoint, which auto-detects promo-claim vs POS-earn.
export default class extends Controller {
  static targets = ["video", "status", "overlay"]
  static values = { resolveUrl: String }

  connect() {
    // If the camera was granted before, hide the "Bật camera" overlay immediately
    // (no flash while the stream warms up); otherwise keep it as a fallback.
    if (this.cameraSeen() && this.hasOverlayTarget) this.overlayTarget.style.display = "none"
    this.start()
  }

  cameraSeen() { try { return localStorage.getItem("qrnavCameraOk") === "1" } catch (e) { return false } }
  rememberCamera(ok) { try { ok ? localStorage.setItem("qrnavCameraOk", "1") : localStorage.removeItem("qrnavCameraOk") } catch (e) {} }

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
      this.rememberCamera(true)

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
      // Access failed/denied — restore the overlay button so the user can retry.
      this.rememberCamera(false)
      if (this.hasOverlayTarget) this.overlayTarget.style.display = ""
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
    value = (value || "").trim()
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
