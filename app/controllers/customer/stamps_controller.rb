module Customer
  class StampsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member = current_member
      @cards = current_workspace.stamp_cards.active.ordered.select(&:running?)
      @memberships = @cards.index_with { |c| c.membership_for(@member) }
    end
  end
end
