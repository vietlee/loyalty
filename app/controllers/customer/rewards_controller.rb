module Customer
  class RewardsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
      @reward = current_workspace.rewards.find(params[:id])
    end

    def redeem
      @reward = current_workspace.rewards.find(params[:id])
      result  = RedeemReward.new(member: current_member, reward: @reward).call
      if result.voucher
        redirect_to member_voucher_path(result.voucher), notice: "Đổi thưởng thành công!"
      else
        redirect_to member_reward_path(@reward), alert: result.error
      end
    end
  end
end
