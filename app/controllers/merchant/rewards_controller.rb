module Merchant
  class RewardsController < BaseController
    before_action :require_manager!, except: [:index]
    before_action :set_reward, only: [:edit, :update, :destroy]

    def index
      @rewards = current_workspace.rewards.ordered.to_a
      @reward  = Reward.new(kind: "voucher", value_unit: "vnd", valid_days: 30, active: true)
    end

    def new
      @reward = Reward.new(kind: "voucher", value_unit: "vnd", valid_days: 30, active: true)
    end

    def create
      @reward = current_workspace.rewards.new(reward_params)
      if @reward.save
        redirect_to merchant_rewards_path, notice: "Đã thêm ưu đãi “#{@reward.title}”."
      else
        @rewards = current_workspace.rewards.ordered.to_a
        render :index, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @reward.update(reward_params)
        redirect_to merchant_rewards_path, notice: "Đã cập nhật ưu đãi."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @reward.destroy
        redirect_to merchant_rewards_path, notice: "Đã xoá ưu đãi."
      else
        redirect_to merchant_rewards_path,
          alert: "Không thể xoá vì ưu đãi đang được sử dụng (voucher đã phát, thẻ tem hoặc chiến dịch). Hãy tắt phát hành thay vì xoá."
      end
    end

    private

    def nav_key = :rewards

    def set_reward
      @reward = current_workspace.rewards.find(params[:id])
    end

    def reward_params
      params.require(:reward).permit(:title, :description, :kind, :icon, :cost_points,
                                     :value, :value_unit, :terms, :stock, :valid_days, :active)
    end
  end
end
