module Merchant
  class DashboardController < BaseController
    def show
      return redirect_to merchant_onboarding_path if current_workspace && !current_workspace.onboarded?
      @members_count   = current_workspace ? Member.count : 0
      @outlets_count   = current_workspace ? Outlet.count : 0
      @program         = current_program
      @tiers           = current_workspace ? current_workspace.tiers.ordered.to_a : []
      if current_workspace
        @points_issued   = PointTransaction.credits.sum(:amount)
        @points_redeemed = PointTransaction.debits.sum(:amount).abs
        @purchases_count = Purchase.count
      else
        @points_issued = @points_redeemed = @purchases_count = 0
      end
      if current_workspace
        @has_checkin  = current_workspace.missions.active.exists?(mission_type: "checkin")
        @checkin_url  = helpers.customer_scan_url(current_workspace, checkin: Checkin.encode(current_workspace)) if @has_checkin
      end
    end

    # Downloadable, printable check-in QR (static workspace token).
    def checkin_qr
      url = helpers.customer_scan_url(current_workspace, checkin: Checkin.encode(current_workspace))
      send_data helpers.qr_svg(url, size: 720),
                type: "image/svg+xml", disposition: "attachment",
                filename: "checkin-#{current_workspace.subdomain}.svg"
    end

    private

    def nav_key = :dashboard
  end
end
