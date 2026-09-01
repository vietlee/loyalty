# Semi-automatic monthly billing: for workspaces with auto-renew on whose
# subscription is within 5 days of expiry (or expired), pre-generate the next
# month's pending invoice + PayOS link so the merchant just clicks to pay.
#
# NOTE: true auto-CHARGE (no click) needs a saved-card / tokenized gateway;
# PayOS one-time links can't be auto-charged, so this generates + reminds.
class BillingRenewalJob < ApplicationJob
  queue_as :default

  def perform
    service = PayosService.new
    return unless service.configured?

    ActsAsTenant.without_tenant do
      Workspace.where(auto_renew: true, status: "active").find_each do |ws|
        next unless ws.paid_until && ws.paid_until <= 5.days.from_now
        ActsAsTenant.with_tenant(ws) { ensure_upcoming_invoice(ws, service) }
      end
    end
  end

  private

  def ensure_upcoming_invoice(ws, service)
    start_d, end_d = ws.next_billing_period
    return if ws.invoices.pending.exists?(period_start: start_d)

    invoice = ws.invoices.create!(plan: ws.plan, amount: ws.plan_record.price,
                                  period_start: start_d, period_end: end_d, status: "pending")
    data = service.create_payment_link(
      order_code:  invoice.payos_order_code,
      amount:      invoice.amount,
      description: "Loyalty #{ws.plan}",
      return_url:  Rails.application.routes.url_helpers.merchant_billing_return_url(
                     code: invoice.payos_order_code, host: "loyalty.czin.net", protocol: "https"),
      cancel_url:  "https://loyalty.czin.net/merchant/billing"
    )
    invoice.update!(checkout_url: data["checkoutUrl"]) if data && data["checkoutUrl"]
    Rails.logger.info("[BillingRenewal] invoice ##{invoice.id} for #{ws.subdomain}")
  rescue => e
    Rails.logger.error("[BillingRenewal] #{ws.subdomain}: #{e.class} #{e.message}")
  end
end
