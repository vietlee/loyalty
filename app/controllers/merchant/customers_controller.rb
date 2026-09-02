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
      end
      @members = scope.order(created_at: :desc).limit(100).to_a
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
  end
end
