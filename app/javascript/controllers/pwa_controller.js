import { Controller } from "@hotwired/stimulus"

// Customer PWA glue: registers the service worker, manages Web Push
// subscription (opt-in), and drives the "Add to Home Screen" banner.
export default class extends Controller {
  static values = { vapid: String, subscribeUrl: String, unsubscribeUrl: String }
  static targets = ["installBanner", "installButton", "iosHint", "pushToggle", "pushLabel"]

  connect() {
    this.registerSW().then(() => this.reflectPush())
    this.setupInstall()
  }

  async registerSW() {
    if (!("serviceWorker" in navigator)) return
    try { await navigator.serviceWorker.register("/service-worker.js") } catch (e) {}
  }

  // ---------- Web Push ----------
  supported() { return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window }

  async currentSub() {
    try { const r = await navigator.serviceWorker.ready; return await r.pushManager.getSubscription() }
    catch (e) { return null }
  }

  async reflectPush() {
    if (!this.hasPushLabelTarget) return
    if (!this.supported()) return this.setPush("unsupported")
    if (Notification.permission === "denied") return this.setPush("blocked")
    this.setPush((await this.currentSub()) ? "on" : "off")
  }

  setPush(state) {
    this.pushState = state
    if (this.hasPushToggleTarget) this.pushToggleTarget.classList.toggle("on", state === "on")
    if (this.hasPushLabelTarget) {
      this.pushLabelTarget.textContent =
        this.data.get(`${state}Text`) || this.data.get("offText") || ""
    }
  }

  async togglePush() {
    if (!this.supported()) return
    if (this.pushState === "blocked") { alert(this.data.get("blockedText")); return }
    const existing = await this.currentSub()
    if (existing) { await this.unsub(existing); this.setPush("off"); return }
    await this.subscribe()
  }

  async subscribe() {
    const perm = await Notification.requestPermission()
    if (perm !== "granted") return this.reflectPush()
    let sub
    try {
      const reg = await navigator.serviceWorker.ready
      sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: this.b64(this.vapidValue) })
    } catch (e) { return this.reflectPush() }
    await this.post(this.subscribeUrlValue, sub.toJSON())
    this.setPush("on")
  }

  async unsub(sub) {
    await this.post(this.unsubscribeUrlValue, { endpoint: sub.endpoint })
    try { await sub.unsubscribe() } catch (e) {}
  }

  async post(url, body) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return fetch(url, {
      method: "POST", credentials: "same-origin",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token || "" },
      body: JSON.stringify(body),
    })
  }

  b64(base64) {
    const pad = "=".repeat((4 - (base64.length % 4)) % 4)
    const raw = atob((base64 + pad).replace(/-/g, "+").replace(/_/g, "/"))
    return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
  }

  // ---------- Add to Home Screen ----------
  setupInstall() {
    if (!this.hasInstallBannerTarget) return
    const standalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone
    if (standalone || this.dismissed()) return

    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferred = e
      this.installBannerTarget.hidden = false
    })

    // iOS Safari has no beforeinstallprompt — show manual instructions instead.
    const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent)
    if (isIos && this.hasIosHintTarget) {
      this.iosHintTarget.hidden = false
      if (this.hasInstallButtonTarget) this.installButtonTarget.hidden = true
      this.installBannerTarget.hidden = false
    }
  }

  async install() {
    if (!this.deferred) return
    this.deferred.prompt()
    await this.deferred.userChoice
    this.deferred = null
    this.installBannerTarget.hidden = true
  }

  dismissInstall() {
    try { localStorage.setItem("a2hs_dismissed", "1") } catch (e) {}
    if (this.hasInstallBannerTarget) this.installBannerTarget.hidden = true
  }

  dismissed() {
    try { return localStorage.getItem("a2hs_dismissed") === "1" } catch (e) { return false }
  }
}
