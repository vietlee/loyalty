module Merchant
  class GamificationController < BaseController
    before_action :require_manager!, only: [:update_wheel]

    def show
      @program     = current_program
      @stamp_cards = current_workspace.stamp_cards.ordered.to_a
      @missions    = current_workspace.missions.ordered.to_a
      @badges      = current_workspace.badges.ordered.to_a
      @wheel       = current_workspace.spin_wheel || current_workspace.build_spin_wheel
      @rewards     = current_workspace.rewards.active.ordered.to_a
      @new_stamp_card = StampCard.new(target_count: 9)
      @new_mission    = Mission.new(period: "daily", reward_points: 20, goal: 1)
    end

    def update_wheel
      wheel = current_workspace.spin_wheel || current_workspace.build_spin_wheel
      rows = (params[:segments] || {}).values
      segs = rows.filter_map do |r|
        label = r[:label].to_s.strip
        next if label.blank?
        value = r[:value].to_i
        { "label" => label, "kind" => value.positive? ? "points" : "none",
          "value" => value, "weight" => [r[:weight].to_i, 1].max,
          "color" => r[:color].presence || "#E08A3C" }
      end
      wheel.segments    = segs
      wheel.cost_points = params[:cost_points].to_i if params[:cost_points].present?
      wheel.daily_free  = params[:daily_free] == "1"
      wheel.save!
      redirect_to merchant_gamification_path, notice: "Đã cập nhật vòng quay may mắn."
    end

    private

    def nav_key = :gamification
  end
end
