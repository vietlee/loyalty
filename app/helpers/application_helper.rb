module ApplicationHelper
  # Workspace resolved purely from the request host — safe to call from Devise
  # controllers (login / password reset) where no tenant is set. Display-only.
  def host_workspace
    return @host_workspace if defined?(@host_workspace)
    sub = request.subdomains.first
    ws  = Workspace.find_by(subdomain: sub) if sub.present? &&
          !TenantResolver::RESERVED_SUBDOMAINS.include?(sub)
    @host_workspace = ws || Workspace.find_by(custom_domain: request.host)
  rescue StandardError
    @host_workspace = nil
  end
  # Icon/favicon URL for a workspace: the uploaded logo when present, else the
  # platform default. Root-relative so it works on any shop host.
  def workspace_icon_url(ws)
    if ws&.logo&.attached?
      # Proxy (not redirect): a stable, cacheable URL that streams the bytes
      # through the app. The redirect variant hands back a short-lived signed
      # disk URL that expires (~5 min) — once the browser/PWA caches that 302,
      # the favicon/logo later 404s and shows a broken "?" image.
      rails_storage_proxy_path(ws.logo, only_path: true)
    else
      "/icon.png"
    end
  end

  # Workspace avatar: the uploaded logo (cover-cropped, inherits the box shape)
  # if present, otherwise the initials. Pass extra style for the box.
  def workspace_avatar(ws, klass: "avatar", style: nil)
    if ws&.logo&.attached?
      content_tag(:div, image_tag(rails_storage_proxy_path(ws.logo, only_path: true), style: "width:100%;height:100%;object-fit:cover;"),
                  class: klass, style: ["overflow:hidden", style].compact.join(";"))
    else
      content_tag(:div, ws&.logo_initials, class: klass, style: style)
    end
  end

  # Builds the customer-app scan-resolve URL for a workspace (what promo / POS
  # QR codes encode). Dev uses the /w/:slug path form on the current host; a
  # custom domain / subdomain is used when configured.
  def customer_scan_url(workspace, query = {})
    host = if workspace.custom_domain.present?
      "#{request.protocol}#{workspace.custom_domain}"
    else
      "#{request.protocol}#{request.host_with_port}/w/#{workspace.slug}"
    end
    "#{host}/scan/resolve?#{query.to_query}"
  end

  # Referral join link a member shares (opens the shop app + stashes the code).
  def customer_join_url(workspace, code)
    host = if workspace.custom_domain.present?
      "#{request.protocol}#{workspace.custom_domain}"
    else
      "#{request.protocol}#{request.host_with_port}/w/#{workspace.slug}"
    end
    "#{host}/join/#{code}"
  end

  # Sensible default perks per tier when a workspace hasn't customised benefits.
  def default_benefits(tier)
    perks = ["Tích ×#{tier.multiplier} điểm mỗi hoá đơn"]
    perks << "Ưu đãi độc quyền theo hạng" if tier.multiplier.to_f > 1
    perks << "Quà sinh nhật đặc biệt"      if tier.multiplier.to_f >= 1.5
    perks << "Ưu tiên hỗ trợ & sự kiện VIP" if tier.multiplier.to_f >= 2
    perks
  end
end
