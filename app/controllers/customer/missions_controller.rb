module Customer
  class MissionsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def index
      @member = current_member
      @missions = current_workspace.missions.active.ordered.to_a
      @progress = @missions.index_with { |m| m.progress_for(@member) }
    end

    def new_submission
      @mission = current_workspace.missions.active.find(params[:id])
      redirect_to member_missions_path unless @mission.photo_proof?
      @progress = @mission.progress_for(current_member)
    end

    def create_submission
      @mission = current_workspace.missions.active.find(params[:id])
      return redirect_to member_missions_path unless @mission.photo_proof?

      mp = @mission.progress_for(current_member)
      mp.save! if mp.new_record?
      ok = mp.submit_photo!(photo: params.dig(:submission, :photo),
                            platform: params.dig(:submission, :platform),
                            note: params.dig(:submission, :note))
      if ok
        # AI auto-verification (Phase B) enqueues here when configured; the manual
        # merchant review queue always works as the fallback.
        VerifyMissionPhotoJob.perform_later(mp.id) if defined?(VerifyMissionPhotoJob) && ClaudeService.configured?
        redirect_to member_missions_path, notice: t("customer.missions.submitted")
      else
        redirect_to new_member_mission_submission_path(@mission), alert: t("customer.missions.submit_failed")
      end
    end
  end
end
