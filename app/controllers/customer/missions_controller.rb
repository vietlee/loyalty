module Customer
  class MissionsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member = current_member
      @missions = current_workspace.missions.active.ordered.to_a
      @progress = @missions.index_with { |m| m.progress_for(@member) }
    end

    def checkin
      mission = current_workspace.missions.active.find(params[:id])
      mp = mission.progress_for(current_member)
      mp.save! if mp.new_record?
      mp.advance!(mission.goal) if mission.mission_type == "checkin" && !mp.completed?
      redirect_to member_missions_path, notice: mp.completed? ? "Đã check-in! +#{mission.reward_points} điểm 🎉" : "Đã ghi nhận."
    end
  end
end
