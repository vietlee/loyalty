module Merchant
  class PaymentsController < BaseController
    before_action :require_manager!

    # "Thanh toán" — find/create the pending invoice for the next month, then open
    # a fresh PayOS checkout.
    def create
      start_d, end_d = current_workspace.next_billing_period
      invoice = current_workspace.invoices.pending.find_by(period_start: start_d) ||
                current_workspace.invoices.create!(
                  plan: current_workspace.plan, amount: current_workspace.plan_record.price,
                  period_start: start_d, period_end: end_d, status: "pending"
                )
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
