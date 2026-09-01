module Merchant
  class PaymentsController < BaseController
    before_action :require_manager!

    # Create an invoice for the next billing month + a PayOS payment link.
    def create
      service = PayosService.new
      unless service.configured?
        return redirect_to merchant_billing_path, alert: "Cổng thanh toán PayOS chưa được cấu hình."
      end

      plan  = current_workspace.plan_record
      start_d, end_d = current_workspace.next_billing_period
      invoice = current_workspace.invoices.pending.find_by(period_start: start_d) ||
                current_workspace.invoices.create!(
                  plan: current_workspace.plan, amount: plan.price,
                  period_start: start_d, period_end: end_d, status: "pending"
                )

      data = service.create_payment_link(
        order_code:  invoice.payos_order_code,
        amount:      invoice.amount,
        description: "Loyalty #{current_workspace.plan}",
        return_url:  merchant_billing_return_url(code: invoice.payos_order_code),
        cancel_url:  merchant_billing_url
      )

      if data && data["checkoutUrl"].present?
        invoice.update!(checkout_url: data["checkoutUrl"])
        redirect_to data["checkoutUrl"], allow_other_host: true
      else
        invoice.update!(status: "failed")
        redirect_to merchant_billing_path, alert: "Không tạo được liên kết thanh toán. Thử lại sau."
      end
    end

    # PayOS redirects here after payment. We confirm with PayOS directly (in case
    # the webhook hasn't landed yet) and apply the payment.
    def return
      order_code = params[:code].to_i
      @invoice = current_workspace.invoices.find_by(payos_order_code: order_code)
      if @invoice && @invoice.pending?
        info = PayosService.new.get_payment_info(order_code)
        if info && info["status"] == "PAID"
          @invoice.apply_payment!(gateway_response: info)
        elsif params[:cancel] == "true" || info&.dig("status") == "CANCELLED"
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

    def nav_key = :billing
  end
end
