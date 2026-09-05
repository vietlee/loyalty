module Merchant
  class CustomersController < BaseController
    before_action :set_member, only: [:show, :adjust]
    before_action :require_manager!, only: [:adjust]

    def index
      @segment = MemberSegments::PRESETS.key?(params[:segment]) ? params[:segment] : "all"
      @counts  = MemberSegments.counts
      scope = MemberSegments.resolve(@segment)
      # Branch staff only see customers who transacted at their outlet.
      if branch_scoped?
        scope = scope.where(id: Purchase.where(outlet_id: scoped_outlet.id).select(:member_id))
      else
        # Owner/manager: optional branch filter (Toàn merchant vs a branch).
        @branches = current_workspace.outlets.order(:name).to_a
        if params[:outlet].present? && (o = @branches.find { |x| x.id.to_s == params[:outlet].to_s })
          @outlet = o
          scope = scope.where(id: Purchase.where(outlet_id: o.id).select(:member_id))
        end
      end
      @q, @sort = params[:q].to_s.strip, params[:sort]
      scope = apply_search(scope, @q)
      scope = apply_sort(scope, @sort)
      @members = scope.limit(100).to_a
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

    def apply_search(scope, q)
      return scope if q.blank?
      like = "%#{q}%"
      scope.where("members.name ILIKE :q OR members.email ILIKE :q OR members.phone ILIKE :q", q: like)
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
