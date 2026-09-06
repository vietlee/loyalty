module Merchant
  class ScannerController < BaseController
    # Minimal staff-mobile landing after a quick-login QR scan: just the shop's
    # logo/name + one button into the counter scanner (earn / redeem). No sidebar.
    def launcher
      render layout: "launcher"
    end

    def show
      @tab = %w[earn redeem pos].include?(params[:tab]) ? params[:tab] : "earn"
      # Owner/manager can switch the active branch for this session.
      if params[:outlet].present? && selectable_outlets.any? { |o| o.id.to_s == params[:outlet].to_s }
        session[:active_outlet_id] = params[:outlet]
      end
      # Kiosk mode = the standalone mobile counter scanner opened from the
      # staff quick-login launcher: same tool, but a minimal chrome (no merchant
      # sidebar/menu) so a phone at the counter behaves like a dedicated device.
      @kiosk = params[:kiosk].present?
      render layout: "scanner_kiosk" if @kiosk
    end

    private

    def nav_key = :scanner
  end
end
