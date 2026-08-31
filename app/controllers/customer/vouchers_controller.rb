module Customer
  class VouchersController < BaseController
    before_action :require_workspace!
    before_action :require_member!
    before_action :set_voucher

    # Renders one of: used confirmation / expired / point-of-use code / detail.
    def show; end

    # Activate (or refresh) the one-time use code, then show the code screen.
    def use
      @voucher.start_use! if @voucher.usable?
      redirect_to member_voucher_path(@voucher)
    end

    # Polled by the use screen so the phone flips to "đã dùng" once the counter
    # verifies it.
    def status
      render json: {
        state: @voucher.state,
        used_at: @voucher.used_at&.strftime("%H:%M %d/%m"),
        outlet: @voucher.used_outlet&.name,
        token_seconds: @voucher.use_token_seconds_left
      }
    end

    private

    def set_voucher
      @voucher = current_member.vouchers.includes(:reward).find(params[:id])
    end
  end
end
