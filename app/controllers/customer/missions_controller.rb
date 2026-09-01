module Customer
  class MissionsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member = current_member
      @missions = current_workspace.missions.active.ordered.to_a
      @progress = @missions.index_with { |m| m.progress_for(@member) }
    end
  end
end
