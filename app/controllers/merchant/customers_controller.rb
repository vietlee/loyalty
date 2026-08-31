module Merchant
  class CustomersController < BaseController
    def index
      @segment = MemberSegments::PRESETS.key?(params[:segment]) ? params[:segment] : "all"
      @counts  = MemberSegments.counts
      @members = MemberSegments.resolve(@segment).order(created_at: :desc).limit(100).to_a
    end

    private

    def nav_key = :customers
  end
end
