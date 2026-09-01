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
      name = ws&.name || "Dynamic Loyalty"
      theme = ws&.theme_value("primary") || "#8C4A2F"
      bg    = ws&.theme_value("surface") || "#FBF6EF"
      start = ws ? member_root_url_for(ws) : "/"
      icon_src = if ws&.logo&.attached?
        Rails.application.routes.url_helpers.rails_blob_path(ws.logo, only_path: true)
      else
        "/icon.png"
      end
      {
        name: name,
        short_name: (ws&.logo_initials || name)[0, 12],
        description: ws&.branding_value("tagline") || "Chương trình tri ân khách hàng",
        start_url: start,
        scope: start,
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
