class GenerateCampaignBannerJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id) or return
    ActsAsTenant.with_tenant(campaign.workspace) do
      result = AiImageService.safe_call(fallback: nil) do
        AiImageService.new.generate(banner_prompt(campaign))
      end
      return if result.nil? # no key / error → merchant can upload manually

      campaign.banner.attach(io: StringIO.new(result[:bytes]),
                             filename: "banner-#{campaign.id}.png",
                             content_type: result[:content_type])
    end
  rescue => e
    Rails.logger.error("[GenerateCampaignBannerJob] #{e.class}: #{e.message}")
  end

  private

  def banner_prompt(c)
    theme = c.workspace.resolved_theme
    title = c.content_value("title").presence || c.name
    <<~PROMPT
      A clean, modern promotional banner for a loyalty campaign at a shop named
      "#{c.workspace.name}". Campaign: "#{title}" (#{c.type_label}).
      Use a warm, inviting palette around #{theme['primary']} and #{theme['primary_2']}.
      Flat vector marketing style, tasteful, uncluttered — decorative background
      imagery only, with clear open space.
      IMPORTANT: do NOT render ANY text, letters, words, numbers, logos, QR codes,
      barcodes, or phone screens with codes. The title and a scannable QR are
      added separately by the system on top of this image, so keep it text-free.
    PROMPT
  end
end
