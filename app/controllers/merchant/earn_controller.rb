module Merchant
  class EarnController < BaseController
    # Step 1 — resolve the customer (scanned QR token, or manual phone entry).
    def lookup
      # Staff may scan a reward use-code (numeric voucher token) here by mistake.
      # Auto-route it to the verify flow so a single scan "just works".
      if (redirect = ScanRouter.reward_use_code(params[:token], current_workspace))
        @voucher = redirect
        return render_voucher_verify
      end

      @member = find_member
      if @member
        render :lookup
      else
        @error = params[:token].present? ? "Mã không hợp lệ hoặc đã hết hạn." : "Không tìm thấy khách với SĐT này."
        render :search, status: :unprocessable_entity
      end
    end

    # Step 2 — award points for the entered bill amount.
    def create
      @member = Member.find_by(id: params[:member_id])
      amount  = params[:amount].to_s.gsub(/[^\d]/, "").to_i
      if @member.nil?
        @error = "Phiên đã hết hạn, vui lòng quét lại."
        return render :search, status: :unprocessable_entity
      end
      if amount <= 0
        @error = "Vui lòng nhập số tiền hoá đơn hợp lệ."
        return render :lookup, status: :unprocessable_entity
      end

      @result = EarnPoints.new(
        member: @member, amount: amount,
        outlet: current_outlet, staff: current_user, source: "staff_scan"
      ).call
      render :create
    end

    private

    def nav_key = :scanner

    def find_member
      if params[:token].present?
        MemberQr.decode(params[:token], workspace: current_workspace)
      elsif params[:email].present?
        Member.find_by(email: params[:email].to_s.strip.downcase)
      elsif params[:phone].present?
        Member.find_by(phone: params[:phone].to_s.gsub(/\s+/, ""))
      end
    end

    # Render the reward-verify result (redeem flow) inside the scan_tool frame,
    # even though staff started on the "Tích điểm" tab.
    def render_voucher_verify
      if @voucher.state == "used"
        render "merchant/redeem/used"
      elsif @voucher.redeem_token_expires_at.nil? || @voucher.redeem_token_expires_at < Time.current
        @error = "Mã sử dụng đã hết hiệu lực. Khách vui lòng tạo lại mã."
        render "merchant/redeem/search", status: :unprocessable_entity
      else
        render "merchant/redeem/confirm"
      end
    end
  end
end
