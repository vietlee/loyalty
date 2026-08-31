module Customer
  class ReferralsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
      @join_url = helpers.customer_join_url(current_workspace, @member.referral_code)
      @invited   = @member.referrals_made.count
      @completed = @member.referrals_made.completed.count
      @reward_points = current_program.referral_points
    end
  end
end
