module Merchant
  class DashboardController < BaseController
    before_action :require_manager!, only: [:rotate_checkin]

    def show
      return redirect_to merchant_onboarding_path if current_workspace && !current_workspace.onboarded?
      @range = resolve_range
      return load_branch_dashboard if current_workspace && branch_scoped?
      @members_count   = current_workspace ? Member.count : 0
      @outlets_count   = current_workspace ? Outlet.count : 0
      @program         = current_program
      @tiers           = current_workspace ? current_workspace.tiers.ordered.to_a : []
      if current_workspace
        @points_issued   = in_range(PointTransaction.credits).sum(:amount)
        @points_redeemed = in_range(PointTransaction.debits).sum(:amount).abs
        @points_outstanding = [Member.sum(:points_balance), 0].max # unredeemed = a liability (state, not range)
        @purchases_count = in_range(Purchase).count
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
      send_data helpers.qr_png(url, size: 720),
                type: "image/png", disposition: "attachment",
                filename: "checkin-#{current_workspace.subdomain}.png"
    end

    # Rotate the check-in token: the old printed QR stops working immediately.
    def rotate_checkin
      current_workspace.rotate_checkin_nonce!
      redirect_to merchant_root_path,
                  notice: "Đã làm mới mã check-in. Mã cũ đã ngừng hoạt động — hãy tải và in lại mã mới."
    end

    private

    RANGE_PRESETS = %w[7d 30d 90d mtd all].freeze

    # Resolve the active date range from ?range= preset or ?from=/?to= custom dates.
    # Flow metrics (points earned/redeemed, purchases, branch performance) honour this;
    # state metrics (member count, outstanding liability, tiers) stay lifetime.
    def resolve_range
      from = parse_range_date(params[:from])
      to   = parse_range_date(params[:to])
      if from || to
        f = (from || Date.new(2000, 1, 1)).beginning_of_day
        t = (to || Date.current).end_of_day
        f, t = t, f if f > t
        return { key: "custom", from: f, to: t,
                 label: "#{f.to_date.strftime('%d/%m/%y')} – #{t.to_date.strftime('%d/%m/%y')}" }
      end
      key = params[:range].to_s.presence_in(RANGE_PRESETS) || "30d"
      now = Time.current
      spec =
        case key
        when "7d"  then { from: 7.days.ago.beginning_of_day, to: now }
        when "90d" then { from: 90.days.ago.beginning_of_day, to: now }
        when "mtd" then { from: now.beginning_of_month, to: now }
        when "all" then { from: nil, to: nil }
        else            { from: 30.days.ago.beginning_of_day, to: now }
        end
      spec.merge(key: key, label: I18n.t("merchant.dashboard.range_#{key}"))
    end

    def parse_range_date(raw)
      return nil if raw.blank?
      Date.iso8601(raw.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    # Scope a relation to the active range (no-op for the "all" preset).
    def in_range(rel)
      @range && @range[:from] ? rel.where(created_at: @range[:from]..@range[:to]) : rel
    end

    GRACE_DAYS = 10 # days after expiry before the workspace is locked

    # Returns a banner descriptor when the subscription needs attention, else nil.
    def subscription_warning(ws)
      pu = ws.paid_until
      return { kind: :inactive, level: :warn, days: nil } if pu.nil?
      left = (pu.to_date - Date.current).to_i
      if ws.trial?
        # Trial: nudge for the whole period (info), escalate to warn near the end.
        return { kind: :trial_over, level: :danger, days: [GRACE_DAYS + left, 0].max } if left < 0
        { kind: :trial, level: (left <= 3 ? :warn : :info), days: left }
      elsif left < 0
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

    # Branch-scoped dashboard: only this outlet's numbers.
    def load_branch_dashboard
      @branch = scoped_outlet
      oid = @branch.id
      base = in_range(Purchase.where(outlet_id: oid))
      @members_count   = base.distinct.count(:member_id)
      @points_issued   = base.sum(:points_earned)
      @purchases_count = base.count
      @revenue         = base.sum(:amount)
      vouchers = Voucher.where(used_outlet_id: oid, state: "used")
      @vouchers_used   = used_in_range(vouchers).count
      render :show
    end

    # Vouchers are dated by used_at, not created_at.
    def used_in_range(rel)
      @range && @range[:from] ? rel.where(used_at: @range[:from]..@range[:to]) : rel
    end

    # Per-branch performance. Purchases and used vouchers are already tagged with
    # the outlet the staff belongs to, so we just group by outlet.
    def build_outlet_stats
      outlets   = current_workspace.outlets.order(:name).to_a
      scoped    = in_range(Purchase)
      purchases = scoped.group(:outlet_id).count
      revenue   = scoped.group(:outlet_id).sum(:amount)
      points    = scoped.group(:outlet_id).sum(:points_earned)
      customers = scoped.distinct.group(:outlet_id).count(:member_id)
      vouchers  = used_in_range(Voucher.where(state: "used")).group(:used_outlet_id).count

      row = lambda do |id, name|
        { id: id, name: name, revenue: revenue[id].to_i, points: points[id].to_i,
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
