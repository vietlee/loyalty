module Admin
  class BillingController < BaseController
    def show
      ActsAsTenant.without_tenant do
        @by_plan = Workspace.where(status: "active").group(:plan).count
        @mrr = @by_plan.sum { |plan, count| Workspace::PLAN_PRICES[plan].to_i * count }
        @active = Workspace.where(status: "active").count
        @trial  = Workspace.where(status: "trial").count
        @past_due = Workspace.where(status: "past_due").to_a
      end
    end

    private

    def nav_key = :billing
  end
end
