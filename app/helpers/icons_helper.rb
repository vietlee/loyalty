module IconsHelper
  # Inline line-icon set (24×24, currentColor stroke) for the customer app.
  ICONS = {
    home:    %(<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.5"/>),
    wallet:  %(<rect x="3" y="6" width="18" height="13" rx="3"/><path d="M3 10h18"/><circle cx="17" cy="14" r="1.4" fill="currentColor" stroke="none"/>),
    gift:    %(<rect x="4" y="9" width="16" height="11" rx="2"/><path d="M4 13h16M12 9v11"/><path d="M12 9C10 9 8 8 8 6.5S9 4 10 4.5 12 7 12 9Zm0 0c2 0 4-1 4-2.5S15 4 14 4.5 12 7 12 9Z"/>),
    scan:    %(<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M4 12h16"/>),
    qrcode:  %(<rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><path d="M14 14h2v2M18 14h2M20 16v2M14 18v2h2M18 20h2" stroke-linecap="round"/>),
    wheel:   %(<circle cx="12" cy="12" r="9"/><path d="M12 3v18M3 12h18M5.6 5.6l12.8 12.8M18.4 5.6 5.6 18.4"/><circle cx="12" cy="12" r="2.2" fill="currentColor" stroke="none"/>),
    user:    %(<circle cx="12" cy="8" r="4"/><path d="M4 20c0-3.5 3.6-6 8-6s8 2.5 8 6"/>),
    bell:    %(<path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10 19a2 2 0 0 0 4 0"/>),
    gear:    %(<circle cx="12" cy="12" r="3.2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M19.1 4.9 17 7M7 17l-2.1 2.1"/>),
    stamp:   %(<circle cx="12" cy="12" r="8"/><path d="m8.5 12 2.3 2.3 4.7-4.7"/>),
    target:  %(<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none"/>),
    medal:   %(<circle cx="12" cy="14" r="6"/><path d="m9 4 3 5 3-5"/><path d="m10.5 13.5 1.5 1.5 3-3" stroke-linecap="round"/>),
    users:   %(<circle cx="9" cy="8" r="3.2"/><path d="M3 19c0-3 2.7-5 6-5s6 2 6 5"/><path d="M16 5.5a3 3 0 0 1 0 5.6M17 19c0-2.2-1-3.8-2.5-4.6"/>)
  }.freeze

  def ui_icon(name, size: 24, klass: nil, stroke: 1.8)
    body = ICONS[name.to_sym] or return "".html_safe
    attrs = %(viewBox="0 0 24 24" width="#{size}" height="#{size}" fill="none" stroke="currentColor" stroke-width="#{stroke}" stroke-linejoin="round" stroke-linecap="round" class="#{klass}" aria-hidden="true")
    "<svg #{attrs}>#{body}</svg>".html_safe
  end
end
