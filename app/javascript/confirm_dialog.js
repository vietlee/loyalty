// Styled HTML confirmation for any element with data-turbo-confirm="…",
// replacing the browser's native confirm(). Themes via CSS variables.
(function () {
  function ask(message) {
    return new Promise((resolve) => {
      const overlay = document.createElement("div")
      overlay.className = "l-confirm-overlay"
      overlay.innerHTML = `
        <div class="l-confirm" role="dialog" aria-modal="true">
          <div class="l-confirm-icon">?</div>
          <div class="l-confirm-msg"></div>
          <div class="l-confirm-actions">
            <button type="button" class="l-btn l-btn-ghost" data-act="no">Huỷ</button>
            <button type="button" class="l-btn l-btn-primary" data-act="yes">Đồng ý</button>
          </div>
        </div>`
      overlay.querySelector(".l-confirm-msg").textContent = message || "Bạn chắc chắn?"
      document.body.appendChild(overlay)
      requestAnimationFrame(() => overlay.classList.add("open"))

      const done = (val) => {
        overlay.classList.remove("open")
        setTimeout(() => overlay.remove(), 180)
        resolve(val)
      }
      overlay.querySelector('[data-act="yes"]').addEventListener("click", () => done(true))
      overlay.querySelector('[data-act="no"]').addEventListener("click", () => done(false))
      overlay.addEventListener("click", (e) => { if (e.target === overlay) done(false) })
      document.addEventListener("keydown", function esc(e) {
        if (e.key === "Escape") { done(false); document.removeEventListener("keydown", esc) }
      })
      overlay.querySelector('[data-act="yes"]').focus()
    })
  }

  const install = () => {
    if (window.Turbo) window.Turbo.setConfirmMethod(ask)
  }
  install()
  document.addEventListener("turbo:load", install, { once: true })
})()
