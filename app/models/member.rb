class Member < ApplicationRecord
  # End customer of a single workspace. Auth = phone + OTP (Warden session via
  # Devise; the password column is unused in dev). Tenant-scoped by workspace.
  acts_as_tenant(:workspace)

  devise :database_authenticatable, :rememberable, :trackable

  LOCALES = %w[vi en].freeze

  belongs_to :workspace
  belongs_to :referred_by, class_name: "Member", optional: true
  has_many :referrals, class_name: "Member", foreign_key: :referred_by_id, dependent: :nullify
  has_many :point_transactions, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :vouchers, dependent: :destroy
  has_many :promo_claims, dependent: :destroy
  has_many :stamp_card_memberships, dependent: :destroy
  has_many :mission_progresses, dependent: :destroy
  has_many :member_badges, dependent: :destroy
  has_many :badges, through: :member_badges
  has_many :spin_logs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :referrals_made, class_name: "Referral", foreign_key: :referrer_id, dependent: :destroy
  has_one  :referral_received, class_name: "Referral", foreign_key: :referred_id, dependent: :destroy

  validates :phone, presence: true,
                    uniqueness: { scope: :workspace_id },
                    format: { with: /\A0\d{8,10}\z/, message: "số điện thoại không hợp lệ" }
  validates :locale, inclusion: { in: LOCALES }

  before_validation :normalize_phone
  before_create :assign_referral_code, :set_placeholder_password

  # Current tier from the cached key (falls back to lowest tier).
  def tier
    ordered_tiers.detect { |t| t.key == tier_key } || ordered_tiers.first
  end

  def ordered_tiers
    @ordered_tiers ||= workspace.tiers.ordered.to_a
  end

  # Points accumulated within the current tier cycle (drives tier standing;
  # not reduced by redemptions).
  def cycle_points
    since = (workspace.program.tier_cycle_months || 12).months.ago
    point_transactions.tier_qualifying.where("created_at >= ?", since).sum(:amount)
  end

  # The tier a given cycle-point total qualifies for.
  def tier_for(points)
    ordered_tiers.select { |t| t.threshold_points <= points }.last || ordered_tiers.first
  end

  def next_tier
    ordered_tiers.detect { |t| t.threshold_points > (tier&.threshold_points || 0) }
  end

  def points_to_next
    nt = next_tier
    nt ? [nt.threshold_points - cycle_points, 0].max : 0
  end

  def tier_progress_pct
    nt = next_tier
    return 100 unless nt
    lo = tier&.threshold_points.to_i
    span = nt.threshold_points - lo
    return 100 if span <= 0
    (((cycle_points - lo).to_f / span) * 100).clamp(0, 100).round
  end

  # Recompute cached balance / lifetime / tier from the ledger. Call after any
  # point movement.
  def recompute_points!
    self.points_balance  = point_transactions.sum(:amount)
    self.lifetime_points = point_transactions.credits.sum(:amount)
    self.tier_key        = tier_for(cycle_points)&.key
    save!(validate: false)
  end

  def display_name
    name.presence || "Thành viên"
  end

  def initials
    display_name.split.map { |w| w[0] }.first(2).join.upcase
  end

  private

  def normalize_phone
    self.phone = phone.to_s.gsub(/\s+/, "").presence
  end

  def assign_referral_code
    return if referral_code.present?
    loop do
      code = "#{workspace&.subdomain.to_s[0, 3].upcase}#{SecureRandom.alphanumeric(4).upcase}"
      unless Member.unscoped.exists?(workspace_id: workspace_id, referral_code: code)
        self.referral_code = code
        break
      end
    end
  end

  def set_placeholder_password
    self.password = SecureRandom.hex(16) if encrypted_password.blank?
  end
end
