module Merchant
  class BillingController < BaseController
    def show
      @workspace = current_workspace
      @plan = current_workspace.plan_record
      @members = Member.count
      @plans = Plan.ordered.to_a
    end

    private

    def nav_key = :billing
  end
end
