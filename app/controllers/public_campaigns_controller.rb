# Public, unauthenticated shareable campaign page. Renders Open Graph meta tags
# so a pasted link (Facebook / Zalo / Messenger) shows a rich preview card, then
# funnels the visitor into the shop's customer app.
class PublicCampaignsController < ActionController::Base
  def show
    @campaign = ActsAsTenant.without_tenant do
      Campaign.includes(:workspace, :reward).find_by(share_slug: params[:share_slug])
    end
    return head :not_found if @campaign.nil?

    @workspace = @campaign.workspace
    ActsAsTenant.with_tenant(@workspace) do
      @banner_url = url_for(@campaign.banner) if @campaign.banner.attached?
      @promo = @campaign.promo_codes.where(active: true).first
    end
    @shop_url = shop_url_for(@workspace)
    # Real, scannable promo QR (the customer scans it to claim). Built on the
    # shop's own host so it resolves to the customer app.
    @promo_scan_url = "#{@shop_url.chomp('/')}/scan/resolve?promo=#{@promo.token}" if @promo
    render layout: false
  rescue ActsAsTenant::Errors::NoTenantSet
    head :not_found
  end

  private

  # The shop's customer app URL: custom domain / subdomain in production,
  # /w/:slug on the current host in dev.
  def shop_url_for(ws)
    proto = request.protocol
    if ws.custom_domain.present?
      "#{proto}#{ws.custom_domain}/"
    elsif Rails.env.production? && ws.subdomain.present?
      "#{proto}#{ws.subdomain}.#{ApplicationController::PLATFORM_HOST}/"
    else
      "#{proto}#{request.host_with_port}/w/#{ws.slug}"
    end
  end
end
