module Merchant
  class PosController < BaseController
    # Generate a per-transaction QR the customer scans to earn (§6.2).
    def create
      amount = params[:amount].to_s.gsub(/[^\d]/, "").to_i
      if amount <= 0
        @error = "Vui lòng nhập số tiền hoá đơn."
        return render :search, status: :unprocessable_entity
      end
      @charge = current_workspace.pos_charges.create!(
        amount: amount, outlet: current_membership&.outlet, staff: current_user
      )
      @charge_url = helpers.customer_scan_url(current_workspace, pos: @charge.token)
      render :show
    end

    private

    def nav_key = :scanner
  end
end
