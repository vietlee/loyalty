module Customer
  class CodesController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
      @token  = MemberQr.encode(@member)
      @since  = Time.current.to_f
    end

    # Fresh rotating QR (SVG) — polled by the countdown so a screenshot expires.
    def token
      color = current_workspace.theme_value(:ink).to_s.delete("#")
      svg = helpers.qr_svg(MemberQr.encode(current_member), color: color, size: 210)
      render json: { svg: svg, ttl: MemberQr::TTL }
    end

    # Poll for an earn that happened after `since` so the phone can animate "+X".
    def recent
      since = Time.at(params[:since].to_f)
      p = current_member.purchases.where("created_at > ?", since).order(:created_at).last
      if p
        render json: { earned: p.points_earned, balance: current_member.reload.points_balance,
                       at: p.created_at.to_f }
      else
        render json: { earned: nil }
      end
    end
  end
end
