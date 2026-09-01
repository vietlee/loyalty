module Webhooks
  # PayOS server-to-server payment confirmation. No CSRF / no auth.
  class PayosController < ActionController::Base
    skip_forgery_protection

    def receive
      payload = JSON.parse(request.body.read)
      service = PayosService.new
      unless service.verify_webhook(payload)
        return render(json: { error: "Invalid signature" }, status: :unauthorized)
      end

      order_code = payload.dig("data", "orderCode").to_i
      invoice = ActsAsTenant.without_tenant { Invoice.find_by(payos_order_code: order_code) }
      return render(json: { success: true }) if invoice.nil?

      ActsAsTenant.with_tenant(invoice.workspace) do
        case payload["code"]
        when "00" then invoice.apply_payment!(gateway_response: payload)
        when "01", "02" then invoice.mark_failed!(gateway_response: payload)
        end
      end
      render json: { success: true }
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :bad_request
    rescue => e
      Rails.logger.error("[PayOS webhook] #{e.class}: #{e.message}")
      render json: { error: "Server error" }, status: :internal_server_error
    end
  end
end
