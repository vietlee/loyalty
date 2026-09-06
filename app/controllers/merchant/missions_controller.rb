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

    def update
      mission = current_workspace.missions.find(params[:id])
      mission.assign_attributes(mission_params)
      mission.proof_config = mission.photo_proof? ? build_proof_config : {}
      if mission.save
        redirect_to merchant_gamification_path, notice: "Đã cập nhật nhiệm vụ “#{mission.title}”."
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

    # social_share config: the merchant ticks which networks are allowed
    # (mission[proof_config][enabled][facebook]=1) and may set per-platform points
    # (mission[proof_config][platforms][facebook]=50; blank/0 = default reward).
    # Only ticked platforms are stored; their keys are the customer's allowlist.
    def build_proof_config
      enabled  = (params.dig(:mission, :proof_config, :enabled) || {}).to_unsafe_h
      pts_in   = (params.dig(:mission, :proof_config, :platforms) || {}).to_unsafe_h
      platforms = Mission::PROOF_PLATFORMS.filter_map do |plat|
        next unless enabled[plat].present?
        [plat, pts_in[plat].to_i]
      end.to_h
      platforms.present? ? { "platforms" => platforms } : {}
    end
  end
end
