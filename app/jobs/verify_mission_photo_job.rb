class VerifyMissionPhotoJob < ApplicationJob
  queue_as :default

  def perform(mission_progress_id)
    mp = MissionProgress.find_by(id: mission_progress_id) or return
    ActsAsTenant.with_tenant(mp.workspace) do
      MissionPhotoVerifier.new(mp).call
    end
  rescue => e
    # Never let a verification failure break the flow — the manual queue remains.
    Rails.logger.error("[VerifyMissionPhotoJob] #{e.class}: #{e.message}")
  end
end
