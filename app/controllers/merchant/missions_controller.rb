module Merchant
  class MissionsController < BaseController
    before_action :require_manager!

    def create
      mission = current_workspace.missions.new(mission_params)
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
  end
end
