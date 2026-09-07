module Pwa
  class ManifestsController < ApplicationController
    include TenantResolver
    skip_before_action :set_locale, raise: false

    # Per-workspace web app manifest so each shop installs as its own branded PWA.
    def show
      @workspace = resolve_workspace
      render json: manifest_hash, content_type: "application/manifest+json"
    end

    private

    def manifest_hash
      ws = @workspace
      shop  = ws&.name || "Dynamic Loyalty"
      theme = ws&.theme_value("primary") || "#8C4A2F"
      bg    = ws&.theme_value("surface") || "#FBF6EF"
      icon_src = if ws&.logo&.attached?
        Rails.application.routes.url_helpers.rails_blob_path(ws.logo, only_path: true)
      else
        "/icon.png"
      end
      # Staff scanner installs as a separate "Quản lý · <shop>" app so a phone can
      # hold both the customer app and the staff scanner without them colliding.
      if params[:app] == "staff"
        loc   = (ws&.locale_default || "vi").to_sym
        name  = I18n.t("merchant.scan.pwa_app_title", shop: shop, locale: loc)
        short = name # home-screen caption must read "Quản lý - <shop>", not just "Quản lý"
        start = "/merchant/scan-home"
        scope = "/merchant"
      else
        name  = shop
        short = shop.to_s[0, 30]
        start = ws ? member_root_url_for(ws) : "/"
        scope = start
      end
      {
        name: name,
        # Home-screen label (Android uses short_name for the icon caption).
        short_name: short,
        description: ws&.branding_value("tagline") || "Chương trình tri ân khách hàng",
        start_url: start,
        scope: scope,
        display: "standalone",
        background_color: bg,
        theme_color: theme,
        lang: ws&.locale_default || "vi",
        icons: [
          { src: icon_src, sizes: "512x512", type: "image/png", purpose: "any" },
          { src: icon_src, sizes: "192x192", type: "image/png", purpose: "any" }
        ]
      }
    end

    def member_root_url_for(ws)
      "/"
    end
  end
end
