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
    end

    private

    def nav_key = :dashboard
  end
end
