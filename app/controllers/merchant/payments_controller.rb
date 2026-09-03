module Merchant
  class PaymentsController < BaseController
    before_action :require_manager!

    # "Thanh toán" — find/create the pending invoice for the next month, then open
    # a fresh PayOS checkout.
    def create
      ws = current_workspace
      # The plan the merchant is paying for lives on the INVOICE, not the
      # workspace — the workspace only switches when payment actually succeeds
      # (see Invoice#apply_payment!). Cancelling leaves the current plan intact.
      chosen = Workspace::PLAN_PRICES.key?(params[:plan]) ? params[:plan] : ws.plan
      price  = Plan.for(chosen).price
      start_d, end_d = ws.first_billing_period
      amount = ws.prorated_amount(price, [start_d, end_d])
      # Pay any invoice that's already due first (re-price to the chosen plan).
      invoice = ws.invoices.pending.order(:period_start).first
      if invoice && (invoice.plan != chosen || invoice.amount != amount)
        invoice.update!(plan: chosen, amount: amount, period_start: start_d, period_end: end_d)
      end
      unless invoice
        # Don't pre-generate a future period's invoice: a paid plan that is still
        # comfortably active has nothing due yet (the renewal invoice is created
        # only when the current period ends). Trials paying to convert are allowed.
        if start_d > Date.current && ws.subscription_active? && !ws.trial?
          return redirect_to merchant_billing_path,
            notice: "Gói đang còn hiệu lực đến #{ws.paid_until.to_date.strftime('%d/%m/%Y')}. Hoá đơn kỳ mới sẽ được tạo khi đến hạn."
        end
        invoice = ws.invoices.create!(
          plan: chosen, amount: amount,
          period_start: start_d, period_end: end_d, status: "pending"
        )
      end
      start_checkout(invoice)
    end

    # "Trả tiếp" — resume payment on an existing pending invoice with a NEW PayOS
    # link (the previous one may have been cancelled/expired).
    def repay
      invoice = current_workspace.invoices.pending.find(params[:id])
      start_checkout(invoice)
    end

    # PayOS redirects here after payment/cancel. We confirm with PayOS directly (in
    # case the webhook hasn't landed) and apply/cancel. PayOS appends orderCode +
    # status; prefer orderCode as the authority over our own ?code fallback.
    def return
      order_code = (params[:orderCode].presence || params[:code]).to_i
      @invoice = current_workspace.invoices.find_by(payos_order_code: order_code)
      if @invoice&.pending?
        info = PayosService.new.get_payment_info(order_code)
        if info && info["status"] == "PAID"
          @invoice.apply_payment!(gateway_response: info)
        elsif params[:cancel] == "true" || params[:status] == "CANCELLED" || info&.dig("status") == "CANCELLED"
          @invoice.update!(status: "cancelled")
        end
      end
    end

    def auto_renew
      current_workspace.update(auto_renew: params[:auto_renew] == "1")
      redirect_to merchant_billing_path,
        notice: current_workspace.auto_renew ? "Đã bật tự động tạo hoá đơn hàng tháng." : "Đã tắt tự động gia hạn."
    end

    private

    # Always mint a fresh order code + link so a stale/cancelled PayOS order can
    # never block a retry, then send the merchant to the checkout.
    def start_checkout(invoice)
      service = PayosService.new
      unless service.configured?
        return redirect_to merchant_billing_path, alert: "Cổng thanh toán PayOS chưa được cấu hình."
      end
      invoice.reassign_order_code!
      data = service.create_payment_link(
        order_code:  invoice.payos_order_code,
        amount:      invoice.amount,
        description: "Loyalty #{invoice.plan}",
        return_url:  merchant_billing_return_url(code: invoice.payos_order_code),
        cancel_url:  merchant_billing_return_url(code: invoice.payos_order_code, cancel: true)
      )
      if data && data["checkoutUrl"].present?
        invoice.update!(checkout_url: data["checkoutUrl"])
        redirect_to data["checkoutUrl"], allow_other_host: true
      else
        redirect_to merchant_billing_path, alert: "Không tạo được liên kết thanh toán. Thử lại sau."
      end
    end

    def nav_key = :billing
  end
end
