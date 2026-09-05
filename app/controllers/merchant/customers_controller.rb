module Merchant
  class CustomersController < BaseController
    before_action :set_member, only: [:show, :adjust]
    before_action :require_manager!, only: [:adjust]

    PER_PAGE = 50

    def index
      @segment = MemberSegments::PRESETS.key?(params[:segment]) ? params[:segment] : "all"
      @counts  = MemberSegments.counts
      @q, @sort = params[:q].to_s.strip, params[:sort]

      if branch_scoped?
        # Branch staff only see customers who transacted at their outlet.
        @applied_outlet = scoped_outlet
      else
        # Owner/manager: optional branch filter (Toàn merchant vs a branch).
        @branches = current_workspace.outlets.order(:name).to_a
        @outlet = @branches.find { |x| x.id.to_s == params[:outlet].to_s } if params[:outlet].present?
        @applied_outlet = @outlet
      end

      base = MemberSegments.audience(segment: @segment, outlet_id: @applied_outlet&.id, q: @q)
      @total = base.count # count on the ungrouped scope (sort may GROUP BY for "spend")
      @page  = [params[:page].to_i, 1].max
      @members  = apply_sort(base, @sort).limit(PER_PAGE).offset((@page - 1) * PER_PAGE).to_a
      @has_more = @total > @page * PER_PAGE

      # Filters to carry into "Soạn thông báo" so the broadcast targets exactly the
      # audience shown here (segment + branch + search), not the whole segment.
      @compose_params = { segment: @segment, outlet: @applied_outlet&.id, q: @q.presence }.compact
    end

    def show
      @transactions   = @member.point_transactions.recent.includes(:outlet, :staff).limit(50).to_a
      @vouchers       = @member.vouchers.recent.includes(:reward).limit(20).to_a
      @purchase_count = @member.purchases.count
      @total_spend    = @member.purchases.sum(:amount)
    end

    # Manual points correction: comp points, fix a mistake, or gift an apology.
    def adjust
      amount = params[:amount].to_s.gsub(/[^\d-]/, "").to_i
      note   = params[:note].to_s.strip
      if amount.zero?
        return redirect_to merchant_customer_path(@member), alert: "Vui lòng nhập số điểm khác 0."
      end

      @member.point_transactions.create!(workspace: current_workspace, kind: "adjust",
                                         amount: amount, note: note.presence, staff: current_user)
      @member.recompute_points!
      verb = amount.positive? ? "cộng" : "trừ"
      redirect_to merchant_customer_path(@member),
                  notice: "Đã #{verb} #{amount.abs} điểm cho #{@member.display_name}."
    end

    private

    def nav_key = :customers

    def set_member
      @member = Member.find(params[:id])
    end

    def apply_sort(scope, sort)
      case sort
      when "points" then scope.order(points_balance: :desc)
      when "spend"
        scope.left_joins(:purchases).group("members.id")
             .order(Arel.sql("COALESCE(SUM(purchases.amount), 0) DESC"))
      else scope.order(created_at: :desc)
      end
    end
  end
end
