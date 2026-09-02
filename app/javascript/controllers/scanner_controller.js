import { Controller } from "@hotwired/stimulus"

// Counter-side QR scanner. Uses the native BarcodeDetector when available;
// otherwise prompts the cashier to use manual entry. On a successful decode it
// fills the hidden token field and submits the lookup form (Turbo frame).
export default class extends Controller {
  static targets = ["video", "token", "form", "status", "overlay"]

  async connect() {
    // Prefer the real permission state (auto-start only when already granted);
    // fall back to the localStorage heuristic when the browser can't answer.
    const state = await this.cameraState()
    if (state === "granted") {
      if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
      this.start()
    } else if (state === "denied") {
      if (this.hasOverlayTarget) this.overlayTarget.style.display = ""
      this.statusTarget.textContent = "Camera đang bị chặn — bật lại quyền trong cài đặt trình duyệt, hoặc nhập mã thủ công."
    } else if (state === "prompt") {
      if (this.hasOverlayTarget) this.overlayTarget.style.display = ""
    } else {
      if (this.cameraSeen() && this.hasOverlayTarget) this.overlayTarget.style.display = "none"
      this.start()
    }
    this.watchPermission()
  }

  async cameraState() {
    try {
      if (navigator.permissions?.query) {
        this._perm = await navigator.permissions.query({ name: "camera" })
        return this._perm.state
      }
    } catch (e) { /* not queryable */ }
    return null
  }

  watchPermission() {
    if (!this._perm) return
    this._perm.onchange = () => {
      if (this._perm.state === "granted" && !this.stream) this.start()
    }
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
        const raw = (codes[0].rawValue || "").trim()
        if (!raw) return
        // The lookup response re-renders this frame (a fresh scanner instance),
        // which would instantly re-detect the same QR still in view — a tight
        // resubmit loop. Dedupe identical scans across instances for a few
        // seconds via window state (survives the Turbo frame swap).
        const now = Date.now()
        if (raw === window.__lastScan && now - (window.__lastScanAt || 0) < 3500) return
        window.__lastScan = raw
        window.__lastScanAt = now
        this.stop()
        this.tokenTarget.value = raw
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
