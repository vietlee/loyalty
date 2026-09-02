import { Controller } from "@hotwired/stimulus"

// Counter-side QR scanner. Uses the native BarcodeDetector when available;
// otherwise prompts the cashier to use manual entry. On a successful decode it
// fills the hidden token field and submits the lookup form (Turbo frame).
export default class extends Controller {
  static targets = ["video", "token", "form", "status", "overlay"]

  connect() {
    // Auto-start; hide the "Bật camera" button immediately if granted before.
    if (this.cameraSeen() && this.hasOverlayTarget) this.overlayTarget.style.display = "none"
    this.start()
  }

  cameraSeen() { try { return localStorage.getItem("scannerCameraOk") === "1" } catch (e) { return false } }
  rememberCamera(ok) { try { ok ? localStorage.setItem("scannerCameraOk", "1") : localStorage.removeItem("scannerCameraOk") } catch (e) {} }

  async start() {
    if (!("BarcodeDetector" in window)) {
      this.statusTarget.textContent = "Trình duyệt không hỗ trợ quét — hãy nhập mã thủ công bên dưới."
      return
    }
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      this.videoTarget.srcObject = this.stream
      await this.videoTarget.play()
      if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
      this.rememberCamera(true)
      this.detector = new BarcodeDetector({ formats: ["qr_code"] })
      this.statusTarget.textContent = "Đang quét…"
      this.timer = setInterval(() => this.tick(), 400)
    } catch (e) {
      this.rememberCamera(false)
      if (this.hasOverlayTarget) this.overlayTarget.style.display = ""
      this.statusTarget.textContent = "Không truy cập được camera — hãy nhập mã thủ công."
    }
  }

  async tick() {
    try {
      const codes = await this.detector.detect(this.videoTarget)
      if (codes.length) {
        this.stop()
        this.tokenTarget.value = codes[0].rawValue
        this.formTarget.requestSubmit()
      }
    } catch (e) { /* transient */ }
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    if (this.stream) this.stream.getTracks().forEach((t) => t.stop())
  }

  disconnect() { this.stop() }
}
