module Merchant
  class RewardsController < BaseController
    before_action :require_manager!, except: [:index]
    before_action :set_reward, only: [:edit, :update, :destroy]

    def index
      @rewards = current_workspace.rewards.listed.ordered.to_a
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
        @rewards = current_workspace.rewards.listed.ordered.to_a
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
      if @reward.stamp_cards.exists? || @reward.campaigns.exists? || @reward.promo_codes.exists?
        # Deleting would break a stamp card / campaign — make the merchant detach first.
        redirect_to merchant_rewards_path,
          alert: "Ưu đãi đang gắn với thẻ tem hoặc chiến dịch. Hãy gỡ/xoá chúng trước khi xoá ưu đãi."
      elsif @reward.vouchers.exists?
        # Voucher đã phát cho khách → không xoá cứng được (mất lịch sử/ví khách).
        # Lưu trữ: ẩn khỏi danh sách + ngừng phát hành, giữ nguyên voucher cũ.
        @reward.update(active: false, archived_at: Time.current)
        redirect_to merchant_rewards_path,
          notice: "Đã lưu trữ ưu đãi (còn voucher đã phát nên giữ lịch sử; đã ẩn khỏi danh sách và ngừng phát hành)."
      else
        @reward.destroy
        redirect_to merchant_rewards_path, notice: "Đã xoá ưu đãi."
      end
    end

    private

    def nav_key = :rewards

    def set_reward
      @reward = current_workspace.rewards.find(params[:id])
    end

    def reward_params
      p = params.require(:reward).permit(:title, :description, :kind, :icon, :cost_points,
                                         :value, :value_unit, :terms, :stock, :valid_days, :active,
                                         :starts_at, :ends_at)
      p[:schedule] = build_schedule
      p
    end

    # Recurring availability from the form: days[] (wday 0-6) + from_hour/to_hour.
    def build_schedule
      sch = params.dig(:reward, :schedule) || {}
      days = Array(sch[:days]).map(&:to_i).select { |d| (0..6).cover?(d) }.uniq.sort
      fh = sch[:from_hour].presence && sch[:from_hour].to_i
      th = sch[:to_hour].presence && sch[:to_hour].to_i
      out = {}
      out["days"] = days if days.present?
      out["from_hour"], out["to_hour"] = fh, th if fh && th
      out
    end
  end
end
