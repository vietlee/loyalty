module Merchant
  class AutomationsController < BaseController
    before_action :require_manager!

    def show
      @rewards = current_workspace.rewards.ordered.to_a
      @cfg     = current_workspace.settings.fetch("automations", {})
    end

    def update
      autos = {
        "welcome"  => { "enabled" => flag("welcome", "enabled"), "reward_id" => field("welcome", "reward_id").presence },
        "birthday" => { "enabled" => flag("birthday", "enabled"), "reward_id" => field("birthday", "reward_id").presence },
        "winback"  => { "enabled" => flag("winback", "enabled"), "reward_id" => field("winback", "reward_id").presence,
                        "days" => field("winback", "days").to_i, "message" => field("winback", "message").to_s.strip.presence },
      }
      current_workspace.update!(settings: current_workspace.settings.merge("automations" => autos))
      redirect_to merchant_automations_path, notice: "Đã lưu cấu hình tự động hoá."
    end

    private

    def nav_key = :automations
    def field(kind, key) = params.dig(:automations, kind, key)
    def flag(kind, key)  = field(kind, key) == "1"
  end
end
