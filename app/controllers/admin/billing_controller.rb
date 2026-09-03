module Admin
  class BillingController < BaseController
    def show
      ActsAsTenant.without_tenant do
        all = Workspace.order(created_at: :desc).to_a
        @groups = all.group_by(&:payment_state)
        paid = @groups[:paid] || []
        @by_plan = paid.group_by(&:plan).transform_values(&:size)
        @mrr = @by_plan.sum { |plan, count| Plan.for(plan).price.to_i * count }
        @paid_count  = paid.size
        @trial_count = (@groups[:trial] || []).size
        @owing = @groups[:owing] || []
        # Concrete debts: unpaid/failed invoices across all tenants, newest first.
        @outstanding = Invoice.where(status: %w[pending failed]).order(created_at: :desc).limit(30).to_a
      end
    end

    private

    def nav_key = :billing
  end
end
