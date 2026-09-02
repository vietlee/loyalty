module Customer
  # Public "About the shop" page: shop info, branches, average rating and every
  # customer's feedback — plus a form for the member to leave/update their own.
  class ReviewsController < BaseController
    before_action :require_workspace!
    before_action :require_member!
    before_action :ensure_public!, only: [:index]

    def index
      @outlets = current_workspace.outlets.order(:id).to_a
      @count   = Rating.count
      @avg     = Rating.average(:stars)&.round(1) || 0
      @ratings = Rating.recent.includes(:member).limit(100).to_a
      @my      = Rating.find_by(member: current_member)
    end

    def new
      @rating = Rating.find_by(member: current_member) || Rating.new(stars: 5)
    end

    def create
      @rating = Rating.find_or_initialize_by(member: current_member)
      @rating.workspace = current_workspace
      @rating.stars     = params[:stars].to_i.clamp(1, 5)
      @rating.comment   = params[:comment].to_s.strip.presence
      if @rating.save
        dest = current_workspace.feedback_public? ? member_shop_about_path : member_profile_path
        redirect_to dest, notice: "Cảm ơn bạn đã đánh giá! ⭐"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def ensure_public!
      redirect_to member_root_path, alert: "Trang này hiện không khả dụng." unless current_workspace.feedback_public?
    end
  end
end
