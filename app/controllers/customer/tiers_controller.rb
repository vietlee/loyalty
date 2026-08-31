module Customer
  class TiersController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
      @tiers  = current_workspace.tiers.ordered.to_a
      @current = @member.tier
    end
  end
end
