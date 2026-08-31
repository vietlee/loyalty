module Merchant
  class EarnController < BaseController
    # Step 1 — resolve the customer (scanned QR token, or manual phone entry).
    def lookup
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
        outlet: current_membership&.outlet, staff: current_user, source: "staff_scan"
      ).call
      render :create
    end

    private

    def nav_key = :scanner

    def find_member
      if params[:token].present?
        MemberQr.decode(params[:token], workspace: current_workspace)
      elsif params[:phone].present?
        Member.find_by(phone: params[:phone].to_s.gsub(/\s+/, ""))
      end
    end
  end
end
