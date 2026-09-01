module Merchant
  class AppearancesController < BaseController
    before_action :require_manager!, only: [:update]

    # Built-in theme presets demonstrating dynamic branding on one layout.
    PRESETS = {
      "cozy_cafe" => {
        "label" => "Cozy Cafe",
        "theme" => { "primary" => "#8C4A2F", "primary_2" => "#E08A3C", "on_primary" => "#FFF7EE",
                     "surface" => "#FBF6EF", "surface_2" => "#F3E9DD", "ink" => "#3A2A20",
                     "ink_2" => "#7A6656", "line" => "#E7D9C9", "radius" => "22px",
                     "font_display" => "Fraunces", "font_body" => "Plus Jakarta Sans" }
      },
      "modern_beauty" => {
        "label" => "Modern Beauty",
        "theme" => { "primary" => "#C64B8C", "primary_2" => "#9B6DD6", "on_primary" => "#FFF5FB",
                     "surface" => "#FBF3F8", "surface_2" => "#F3E6F1", "ink" => "#3A2634",
                     "ink_2" => "#7C6376", "line" => "#EBD7E6", "radius" => "26px",
                     "font_display" => "Playfair Display", "font_body" => "Plus Jakarta Sans" }
      },
      "retail_bold" => {
        "label" => "Retail Bold",
        "theme" => { "primary" => "#111111", "primary_2" => "#E0B54A", "on_primary" => "#FFFDF5",
                     "surface" => "#FAFAF7", "surface_2" => "#EFEDE6", "ink" => "#1A1A1A",
                     "ink_2" => "#6B6B66", "line" => "#E2E0D8", "radius" => "14px",
                     "font_display" => "Fraunces", "font_body" => "Inter" }
      }
    }.freeze

    def show
      @workspace = current_workspace
      @presets   = PRESETS
    end

    def update
      @workspace = current_workspace
      if params[:preset].present? && PRESETS.key?(params[:preset])
        @workspace.theme = PRESETS[params[:preset]]["theme"]
      else
        @workspace.theme    = (@workspace.theme || {}).merge(theme_params.to_h)
        @workspace.branding = (@workspace.branding || {}).merge(branding_params.to_h)
        @workspace.logo.attach(params[:logo]) if params[:logo].present?
      end

      if @workspace.save
        redirect_to merchant_appearance_path, notice: "Đã cập nhật giao diện thương hiệu."
      else
        @presets = PRESETS
        render :show, status: :unprocessable_entity
      end
    end

    private

    def nav_key = :appearance

    def theme_params
      params.fetch(:theme, {}).permit(:primary, :primary_2, :on_primary, :surface, :surface_2,
                                      :ink, :ink_2, :line, :radius, :font_display, :font_body)
    end

    def branding_params
      params.fetch(:branding, {}).permit(:logo_text, :tagline, :customer_term, :tone)
    end
  end
end
