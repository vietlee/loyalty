module Merchant
  class MissionsController < BaseController
    before_action :require_manager!

    def create
      mission = current_workspace.missions.new(mission_params)
      mission.proof_config = build_proof_config if mission.photo_proof?
      if mission.save
        redirect_to merchant_gamification_path, notice: "Đã tạo nhiệm vụ “#{mission.title}”."
      else
        redirect_to merchant_gamification_path, alert: mission.errors.full_messages.to_sentence
      end
    end

    def destroy
      current_workspace.missions.find(params[:id]).destroy
      redirect_to merchant_gamification_path, notice: "Đã xoá nhiệm vụ."
    end

    private

    def nav_key = :gamification

    def mission_params
      params.require(:mission).permit(:title, :icon, :mission_type, :period, :goal, :reward_points, :active)
    end

    # Per-platform point overrides for social_share missions:
    # mission[proof_config][platforms][facebook] = "50", etc. Blanks are dropped.
    def build_proof_config
      platforms = params.dig(:mission, :proof_config, :platforms) || {}
      pts = platforms.to_unsafe_h.filter_map do |plat, val|
        next unless Mission::PROOF_PLATFORMS.include?(plat.to_s) && val.present?
        [plat.to_s, val.to_i]
      end.to_h
      pts.present? ? { "platforms" => pts } : {}
    end
  end
end
