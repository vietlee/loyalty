module Customer
  # Public "About the shop" page (info, branches, all customers' feedback) and
  # the member's own reviews — a member may leave many and edit their own.
  class ReviewsController < BaseController
    before_action :require_workspace!
    before_action :require_member!
    before_action :ensure_public!, only: [:index]

    def index
      @outlets  = current_workspace.outlets.order(:id).to_a
      @count    = Rating.count
      @avg      = Rating.average(:stars)&.round(1) || 0
      @ratings  = Rating.recent.includes(:member).limit(100).to_a
      @mine     = Rating.where(member: current_member).recent.to_a
      @my_count = @mine.size
    end

    def new
      @rating = Rating.new(stars: 5) # always a fresh review
    end

    def create
      @rating = Rating.new(workspace: current_workspace, member: current_member,
                           stars: stars_param, comment: comment_param)
      if @rating.save
        redirect_to after_save_path, notice: "Cảm ơn bạn đã đánh giá! ⭐"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @rating = own_rating or return redirect_to(after_save_path, alert: "Không tìm thấy đánh giá.")
    end

    def update
      @rating = own_rating or return redirect_to(after_save_path, alert: "Không tìm thấy đánh giá.")
      if @rating.update(stars: stars_param, comment: comment_param)
        redirect_to after_save_path, notice: "Đã cập nhật đánh giá của bạn."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def own_rating = Rating.where(member: current_member).find_by(id: params[:id])
    def stars_param = params[:stars].to_i.clamp(1, 5)
    def comment_param = params[:comment].to_s.strip.presence
    def after_save_path = current_workspace.feedback_public? ? member_shop_about_path : member_profile_path

    def ensure_public!
      redirect_to member_root_path, alert: "Trang này hiện không khả dụng." unless current_workspace.feedback_public?
    end
  end
end
