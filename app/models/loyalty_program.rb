class LoyaltyProgram < ApplicationRecord
  acts_as_tenant(:workspace)

  SCAN_MODES = %w[staff_scans_member member_scans_pos both].freeze

  belongs_to :workspace

  validates :scan_mode, inclusion: { in: SCAN_MODES }
  validates :earn_points, :earn_per_amount, numericality: { greater_than: 0 }

  # Points earned for a purchase of `amount` (currency units), before tier multiplier.
  def points_for(amount)
    return 0 unless points_enabled && earn_per_amount.to_i.positive?
    (amount.to_f / earn_per_amount * earn_points).floor
  end

  def scan_staff?  = %w[staff_scans_member both].include?(scan_mode)
  def scan_member? = %w[member_scans_pos both].include?(scan_mode)

  def earn_rate_label
    "#{earn_points} điểm / #{ActiveSupport::NumberHelper.number_to_delimited(earn_per_amount)}#{currency == 'VND' ? 'đ' : ' ' + currency}"
  end
end
