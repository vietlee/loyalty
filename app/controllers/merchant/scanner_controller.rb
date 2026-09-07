module Merchant
  class ScannerController < BaseController
    # Minimal staff-mobile landing after a quick-login QR scan: just the shop's
    # logo/name + one button into the counter scanner (earn / redeem). No sidebar.
    def launcher
      render layout: "launcher"
    end

    def show
      @tab = %w[earn redeem pos checkin].include?(params[:tab]) ? params[:tab] : "earn"
      # Owner/manager can switch the active branch for this session.
      if params[:outlet].present? && selectable_outlets.any? { |o| o.id.to_s == params[:outlet].to_s }
        session[:active_outlet_id] = params[:outlet]
      end
      # Branch check-in QR tab: owner may show any branch; a manager/staff only
      # their own branch. Independent of the earn/redeem branch attribution above.
      if @tab == "checkin"
        @qr_outlets = checkin_qr_outlets
        @qr_outlet  = @qr_outlets.find { |o| o.id.to_s == params[:qr_outlet].to_s } || @qr_outlets.first
      end
      # Kiosk mode = the standalone mobile counter scanner opened from the
      # staff quick-login launcher: same tool, but a minimal chrome (no merchant
      # sidebar/menu) so a phone at the counter behaves like a dedicated device.
      @kiosk = params[:kiosk].present?
      render layout: "scanner_kiosk" if @kiosk
    end

    private

    def nav_key = :scanner

    # Branches whose check-in QR the current user may display.
    #   owner            → every branch (can pick)
    #   manager / staff  → only the branch they belong to
    def checkin_qr_outlets
      m = current_membership
      return current_workspace.outlets.order(:name).to_a if m&.owner?
      [m&.outlet].compact
    end
  end
end
