module Customer
  class HomeController < BaseController
    def show
      if current_workspace.nil?
        # Apex host (no shop resolved) → marketing landing page.
        @plans = Plan.ordered.to_a
        @plans = Plan::DEFAULTS.map { |d| Plan.new(d) } if @plans.empty?
        render "customer/home/landing", layout: "marketing"
      elsif !member_signed_in? || current_member&.workspace_id != current_workspace.id
        redirect_to member_login_path
      else
        @member = current_member
        @tier   = @member.tier
        @unread = @member.notifications.unread.count
        prog = current_workspace.program
        if prog.gamification_enabled
          @missions = current_workspace.missions.active.ordered.where(period: "daily").limit(3).to_a
          @progress = @missions.index_with { |m| m.progress_for(@member) }
          @has_stamps = current_workspace.stamp_cards.active.exists?
        end
        render :show
      end
    end
  end
end
