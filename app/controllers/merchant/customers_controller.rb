module Merchant
  class CustomersController < BaseController
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

    private

    def nav_key = :customers
  end
end
