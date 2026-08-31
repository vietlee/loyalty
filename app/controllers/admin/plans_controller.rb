module Admin
  class PlansController < BaseController
    def index
      Plan.seed_defaults! if Plan.count.zero?
      @plans = Plan.ordered.to_a
    end

    def update
      @plan = Plan.find(params[:id])
      if @plan.update(plan_params)
        redirect_to admin_plans_path, notice: "Đã cập nhật gói #{@plan.name}."
      else
        @plans = Plan.ordered.to_a
        render :index, status: :unprocessable_entity
      end
    end

    private

    def nav_key = :plans

    def plan_params
      p = params.require(:plan).permit(:name, :price, :max_outlets, :max_members,
                                       :allow_stamps, :allow_gamification, :allow_campaigns,
                                       :allow_custom_domain, :allow_ab_testing, :features_text)
      # blank limit fields → unlimited (nil)
      p[:max_outlets] = p[:max_outlets].presence
      p[:max_members] = p[:max_members].presence
      features = p.delete(:features_text).to_s.split("\n").map(&:strip).reject(&:blank?)
      p.to_h.merge(features: features)
    end
  end
end
