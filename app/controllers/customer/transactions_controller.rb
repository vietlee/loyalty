module Customer
  class TransactionsController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    PER = 30

    def index
      @member = current_member
      @page = [params[:page].to_i, 1].max
      @transactions = @member.point_transactions.recent.limit(PER).offset((@page - 1) * PER).to_a
      @has_more = @member.point_transactions.count > @page * PER
    end
  end
end
