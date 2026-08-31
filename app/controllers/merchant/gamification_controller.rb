module Merchant
  class GamificationController < BaseController
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

    private

    def nav_key = :gamification
  end
end
