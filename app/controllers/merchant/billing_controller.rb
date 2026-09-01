module Merchant
  class BillingController < BaseController
    def show
      @workspace = current_workspace
      @plan = current_workspace.plan_record
      @members = Member.count
      @plans = Plan.ordered.to_a
      @invoices = current_workspace.invoices.recent.limit(12).to_a
      @next_start, @next_end = current_workspace.next_billing_period
      @payos_ready = PayosService.new.configured?
    end

    private

    def nav_key = :billing
  end
end
