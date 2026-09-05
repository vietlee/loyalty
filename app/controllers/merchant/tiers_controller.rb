module Merchant
  # Bulk-edit membership tiers (name, threshold, points multiplier, colors).
  class TiersController < BaseController
    before_action :require_manager!

    def update
      rows = params.fetch(:tiers, {})
      current_workspace.tiers.find_each do |tier|
        attrs = rows[tier.id.to_s]
        next if attrs.blank?
        benefits = attrs[:benefits].to_s.split(",").map(&:strip).reject(&:blank?)
        tier.update(
          name:             attrs[:name].presence || tier.name,
          threshold_points: attrs[:threshold_points].to_i,
          multiplier:       [attrs[:multiplier].to_f, 1.0].max,
          benefits:         benefits,
          gradient_from:    attrs[:gradient_from].presence || tier.gradient_from,
          gradient_to:      attrs[:gradient_to].presence || tier.gradient_to
        )
      end
      redirect_to merchant_loyalty_program_path, notice: t("merchant.tiers.saved")
    end

    private

    def nav_key = :program
  end
end
