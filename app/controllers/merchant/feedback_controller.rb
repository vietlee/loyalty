module Merchant
  class FeedbackController < BaseController
    before_action :require_manager!

    PER_PAGE = 50

    def show
      @count   = Rating.count
      @avg     = Rating.average(:stars)&.round(1) || 0
      @dist    = (1..5).to_h { |s| [s, Rating.where(stars: s).count] }
      @page    = [params[:page].to_i, 1].max
      @ratings = Rating.recent.includes(:member).limit(PER_PAGE).offset((@page - 1) * PER_PAGE).to_a
      @has_more = @count > @page * PER_PAGE
    end

    def update
      current_workspace.update!(
        settings: current_workspace.settings.merge("feedback_public" => params[:feedback_public] == "1")
      )
      redirect_to merchant_feedback_path, notice: "Đã cập nhật hiển thị trang đánh giá."
    end

    private

    def nav_key = :feedback
  end
end
