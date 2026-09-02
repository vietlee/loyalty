module Merchant
  class DashboardController < BaseController
    before_action :require_manager!, only: [:rotate_checkin]

    def show
      return redirect_to merchant_onboarding_path if current_workspace && !current_workspace.onboarded?
      @members_count   = current_workspace ? Member.count : 0
      @outlets_count   = current_workspace ? Outlet.count : 0
      @program         = current_program
      @tiers           = current_workspace ? current_workspace.tiers.ordered.to_a : []
      if current_workspace
        @points_issued   = PointTransaction.credits.sum(:amount)
        @points_redeemed = PointTransaction.debits.sum(:amount).abs
        @purchases_count = Purchase.count
        @redemption_rate = @points_issued.zero? ? 0 : (@points_redeemed.to_f / @points_issued * 100).round
        @active_members  = Member.where("lifetime_points > 0").count
        @member_growth   = monthly_member_growth
        @tier_counts     = @tiers.map { |t| [t, Member.where(tier_key: t.key).count] }
        @outlet_stats    = build_outlet_stats
        @has_checkin     = current_workspace.missions.active.exists?(mission_type: "checkin")
        @checkin_url     = helpers.customer_scan_url(current_workspace, checkin: Checkin.encode(current_workspace)) if @has_checkin
        @sub_warning     = subscription_warning(current_workspace)
      else
        @points_issued = @points_redeemed = @purchases_count = @redemption_rate = @active_members = 0
        @member_growth = []
        @tier_counts   = []
      end
    end

    # Downloadable, printable check-in QR (static workspace token).
    def checkin_qr
      url = helpers.customer_scan_url(current_workspace, checkin: Checkin.encode(current_workspace))
      send_data helpers.qr_svg(url, size: 720),
                type: "image/svg+xml", disposition: "attachment",
                filename: "checkin-#{current_workspace.subdomain}.svg"
    end

    # Rotate the check-in token: the old printed QR stops working immediately.
    def rotate_checkin
      current_workspace.rotate_checkin_nonce!
      redirect_to merchant_root_path,
                  notice: "Đã làm mới mã check-in. Mã cũ đã ngừng hoạt động — hãy tải và in lại mã mới."
    end

    private

    GRACE_DAYS = 10 # days after expiry before the workspace is locked

    # Returns a banner descriptor when the subscription needs attention, else nil.
    def subscription_warning(ws)
      pu = ws.paid_until
      return { kind: :inactive, level: :warn, days: nil } if pu.nil?
      left = (pu.to_date - Date.current).to_i
      if left < 0
        { kind: :expired, level: :danger, days: [GRACE_DAYS + left, 0].max }
      elsif left <= 7
        { kind: :expiring, level: :warn, days: left }
      end
    end

    # New members per month over the last 6 months, with the running total.
    def monthly_member_growth
      months = (0..5).map { |i| Date.current.beginning_of_month << (5 - i) } # oldest→newest
      raw = Member.where("created_at >= ?", months.first)
                  .group("date_trunc('month', created_at)").count
      running = Member.where("created_at < ?", months.first).count
      months.map do |m|
        added = raw.find { |k, _| k.to_date.beginning_of_month == m }&.last.to_i
        running += added
        { label: I18n.l(m, format: "%m/%y"), value: added, total: running }
      end
    end

    # Per-branch performance. Purchases and used vouchers are already tagged with
    # the outlet the staff belongs to, so we just group by outlet.
    def build_outlet_stats
      outlets   = current_workspace.outlets.order(:name).to_a
      purchases = Purchase.group(:outlet_id).count
      revenue   = Purchase.group(:outlet_id).sum(:amount)
      points    = Purchase.group(:outlet_id).sum(:points_earned)
      customers = Purchase.distinct.group(:outlet_id).count(:member_id)
      vouchers  = Voucher.where(state: "used").group(:used_outlet_id).count

      row = lambda do |id, name|
        { name: name, revenue: revenue[id].to_i, points: points[id].to_i,
          purchases: purchases[id].to_i, customers: customers[id].to_i, vouchers: vouchers[id].to_i }
      end
      rows = outlets.map { |o| row.call(o.id, o.name) }
      # Activity tagged to no outlet (staff without a branch, member self-scan).
      if purchases[nil].to_i.positive? || vouchers[nil].to_i.positive?
        rows << row.call(nil, "Chưa gán chi nhánh")
      end
      rows.sort_by { |r| -r[:revenue] }
    end

    def nav_key = :dashboard
  end
end
