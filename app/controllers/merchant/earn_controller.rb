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
        outlet: current_outlet, staff: current_user, source: "staff_scan"
      ).call
      render :create
    end

    private

    def nav_key = :scanner

    def find_member
      if params[:token].present?
        log_token_failure(params[:token]) # TEMP diagnostic
        MemberQr.decode(params[:token], workspace: current_workspace)
      elsif params[:email].present?
        Member.find_by(email: params[:email].to_s.strip.downcase)
      elsif params[:phone].present?
        Member.find_by(phone: params[:phone].to_s.gsub(/\s+/, ""))
      end
    end

    # TEMP diagnostic — categorise why a scanned token fails to resolve.
    def log_token_failure(raw)
      tok = raw.to_s.strip
      reason =
        begin
          data = MemberQr.verifier.verify(tok)
          if data["w"].to_i != current_workspace.id
            "wrong_workspace(token_w=#{data['w']} current=#{current_workspace.id})"
          elsif Member.find_by(id: data["m"]).nil?
            "member_missing(m=#{data['m']})"
          else
            "OK"
          end
        rescue ActiveSupport::MessageVerifier::ExpiredMessage then "EXPIRED"
        rescue ActiveSupport::MessageVerifier::InvalidSignature then "BAD_SIGNATURE"
        rescue => e then "ERR(#{e.class})"
        end
      Rails.logger.info("[SCAN-DIAG] len=#{tok.length} head=#{tok[0, 10]} tail=#{tok[-6..]} url?=#{tok.start_with?('http')} reason=#{reason}")
    end
  end
end
