module Merchant
  class FeedbackController < BaseController
    before_action :require_manager!

    def show
      @count   = Rating.count
      @avg     = Rating.average(:stars)&.round(1) || 0
      @dist    = (1..5).to_h { |s| [s, Rating.where(stars: s).count] }
      @ratings = Rating.recent.includes(:member).limit(200).to_a
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
