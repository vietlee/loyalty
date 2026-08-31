module Customer
  class BadgesController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member = current_member
      Gamification.evaluate_badges(@member, current_workspace) # reflect existing history
      @badges = current_workspace.badges.ordered.to_a
      @earned = @member.member_badges.pluck(:badge_id).to_set
    end
  end
end
