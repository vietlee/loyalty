module Merchant
  class CampaignsController < BaseController
    before_action :require_manager!, except: [:index, :show]
    before_action :set_campaign, only: [:show, :qr]

    def index
      @campaigns = current_workspace.campaigns.recent.includes(:reward).to_a
    end

    def new
      @campaign = current_workspace.campaigns.new(campaign_type: "promo_voucher", audience: "all",
                                                  status: "running", starts_at: Time.current)
      @rewards = current_workspace.rewards.active.ordered.to_a
    end

    def create
      unless current_workspace.plan_allows?(:campaigns)
        return redirect_to merchant_campaigns_path, alert: "Chiến dịch có ở gói Growth trở lên. Vui lòng nâng cấp gói."
      end
      @campaign = current_workspace.campaigns.new(campaign_params)
      if @campaign.save
        maybe_generate_promo!
        redirect_to merchant_campaign_path(@campaign), notice: "Đã tạo chiến dịch “#{@campaign.name}”."
      else
        @rewards = current_workspace.rewards.active.ordered.to_a
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @promo = @campaign.promo_codes.first
      @promo_url = helpers.customer_scan_url(current_workspace, promo: @promo.token) if @promo
    end

    # Downloadable promo QR (SVG) for printing on posters / receipts.
    def qr
      promo = @campaign.promo_codes.first
      raise ActiveRecord::RecordNotFound unless promo
      url = helpers.customer_scan_url(current_workspace, promo: promo.token)
      svg = helpers.qr_svg(url, color: "1A1A1A", size: 600)
      send_data svg, type: "image/svg+xml", filename: "promo-#{promo.token}.svg", disposition: "attachment"
    end

    private

    def nav_key = :campaigns

    def set_campaign
      @campaign = current_workspace.campaigns.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :campaign_type, :audience, :reward_id,
                                       :starts_at, :ends_at, :status,
                                       content: [:title, :body, :tone])
    end

    def maybe_generate_promo!
      return unless params[:generate_qr] == "1" && @campaign.reward_id.present?
      current_workspace.promo_codes.create!(
        campaign: @campaign, reward: @campaign.reward,
        max_claims: params[:max_claims].presence&.to_i,
        starts_at: @campaign.starts_at, ends_at: @campaign.ends_at, active: true
      )
    end
  end
end
