module Customer
  class WalletController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member   = current_member
      @rewards  = current_workspace.rewards.redeemable.ordered.to_a.select(&:available?)
      @vouchers = @member.vouchers.recent.includes(:reward).to_a
      @expiring = @vouchers.select { |v| v.usable? && v.expires_at && v.expires_at <= 7.days.from_now }
    end
  end
end
