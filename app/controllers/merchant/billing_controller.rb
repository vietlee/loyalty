module Merchant
  class BillingController < BaseController
    def show
      @workspace = current_workspace
      @price = Workspace::PLAN_PRICES[@workspace.plan].to_i
      @members = Member.count
      @plans = Workspace::PLAN_PRICES
    end

    private

    def nav_key = :billing
  end
end
