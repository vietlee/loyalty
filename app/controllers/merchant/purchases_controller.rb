module Merchant
  # Undoing a bill rung up by mistake. Permission lives on the record itself
  # (Purchase#voidable_by?): managers always, the cashier who created it while
  # it's still fresh.
  class PurchasesController < BaseController
    def void
      @purchase = Purchase.find(params[:id])

      unless @purchase.voidable_by?(current_user, current_membership)
        return respond(alert: t("merchant.void.not_allowed"))
      end

      result = VoidPurchase.new(purchase: @purchase, staff: current_user,
                                reason: params[:reason]).call
      if result.ok
        respond(notice: t("merchant.void.done",
                          n: number_with_delimiter(result.points_reversed),
                          name: @purchase.member.display_name))
      else
        respond(alert: result.error)
      end
    end

    private

    def nav_key = :transactions

    def number_with_delimiter(n) = helpers.number_with_delimiter(n)

    # The scanner posts from inside the "scan_tool" turbo-frame and must get a
    # frame response back; everywhere else a plain redirect is right.
    def respond(notice: nil, alert: nil)
      if params[:frame] == "scan_tool"
        @message = notice || alert
        @ok = notice.present?
        render "merchant/earn/voided", status: (alert ? :unprocessable_entity : :ok)
      else
        redirect_back fallback_location: merchant_transactions_path, notice: notice, alert: alert
      end
    end
  end
end
