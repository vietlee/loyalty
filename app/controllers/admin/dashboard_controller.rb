module Admin
  class DashboardController < BaseController
    def show
      ActsAsTenant.without_tenant do
        @workspaces_count = Workspace.count
        @active_count     = Workspace.where(status: "active").count
        @trial_count      = Workspace.where(status: "trial").count
        @members_count    = Member.count
        @recent           = Workspace.order(created_at: :desc).limit(8).to_a
      end
    end

    private

    def nav_key = :dashboard
  end
end
