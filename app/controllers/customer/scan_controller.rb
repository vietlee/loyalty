module Customer
  class ScanController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
    end

    # Multi-purpose resolver (§6.2 POS earn + §6.6 promo claim). Reached from the
    # in-app camera or a deep-linked promo/POS QR.
    def resolve
      parse_code!(params[:code]) if params[:code].present?
      if params[:promo].present?
        handle_promo(params[:promo])
      elsif params[:pos].present?
        handle_pos(params[:pos])
      elsif params[:checkin].present?
        handle_checkin(params[:checkin])
      elsif params[:token].present?
        dispatch_token(params[:token])
      else
        invalid!
      end
    end

    private

    # ---- Store check-in (scan the on-site QR) ----
    def handle_checkin(token)
      ok, outlet_id = Checkin.decode(token, workspace: current_workspace)
      return invalid! unless ok
      outlet = outlet_id.present? ? current_workspace.outlets.find_by(id: outlet_id) : nil
      status, points = Checkin.check_in!(current_member, current_workspace, outlet)
      @points = points
      case status
      when :done    then render :checkin_success
      when :already then render :checkin_already, status: :unprocessable_entity
      else render :checkin_none, status: :unprocessable_entity
      end
    end

    # ---- Promo claim-to-wallet (§6.6) ----
    def handle_promo(token)
      @promo = current_workspace.promo_codes.find_by(token: token)
      return invalid! unless @promo
      @promo.register_scan!
      @voucher, err = @promo.claim!(current_member)
      case err
      when nil      then render :claim_success
      when :already then render :claim_already
      else render :claim_unavailable, status: :unprocessable_entity
      end
    end

    # ---- POS self-scan earn (§6.2) ----
    def handle_pos(token)
      @charge = current_workspace.pos_charges.find_by(token: token)
      return invalid! unless @charge
      @result, err = @charge.claim!(current_member)
      case err
      when nil      then render :earn_success
      when :used    then render :pos_used, status: :unprocessable_entity
      when :expired then render :pos_expired, status: :unprocessable_entity
      else invalid!
      end
    end

    def invalid!
      @message = t("customer.scan.invalid_message")
      render :invalid, status: :unprocessable_entity
    end

    def dispatch_token(token)
      if PromoCode.exists?(token: token) then handle_promo(token)
      elsif PosCharge.exists?(token: token) then handle_pos(token)
      else invalid!
      end
    end

    # Accept a bare token or a scanned URL carrying promo=/pos=.
    def parse_code!(raw)
      s = raw.to_s.strip
      if s =~ /[?&]promo=([^&]+)/ then params[:promo] = $1
      elsif s =~ /[?&]pos=([^&]+)/ then params[:pos] = $1
      elsif s =~ /[?&]checkin=([^&]+)/ then params[:checkin] = CGI.unescape($1)
      else params[:token] = s[%r{/([A-Za-z0-9]+)\z}, 1] || s
      end
    end
  end
end
