class Voucher < ApplicationRecord
  acts_as_tenant(:workspace)

  STATES  = %w[active used expired].freeze
  SOURCES = %w[redeem claim_qr campaign birthday referral].freeze
  USE_TTL = 12.minutes # point-of-use code lifetime (§6.4)

  belongs_to :workspace
  belongs_to :member
  belongs_to :reward
  belongs_to :used_outlet, class_name: "Outlet", optional: true
  belongs_to :used_by_staff, class_name: "User", optional: true
  has_many :point_transactions, as: :source, dependent: :nullify

  validates :code, presence: true, uniqueness: { scope: :workspace_id }
  validates :state, inclusion: { in: STATES }

  before_validation :assign_code, on: :create

  scope :recent,   -> { order(created_at: :desc) }
  scope :active,   -> { where(state: "active") }
  scope :used,     -> { where(state: "used") }
  scope :expiring_soon, -> { active.where("expires_at IS NOT NULL AND expires_at <= ?", 7.days.from_now) }

  def expired?
    state == "expired" || (expires_at.present? && expires_at < Time.current)
  end

  def usable?
    state == "active" && !expired?
  end

  # Generate (or refresh) the one-time use code shown at the counter.
  def start_use!
    if redeem_token.blank? || redeem_token_expires_at.nil? || redeem_token_expires_at < Time.current
      update!(redeem_token: self.class.fresh_use_token(workspace),
              redeem_token_expires_at: USE_TTL.from_now)
    end
    self
  end

  def use_token_seconds_left
    return 0 if redeem_token_expires_at.nil?
    [(redeem_token_expires_at - Time.current).to_i, 0].max
  end

  # Permanently redeem the voucher at the counter — locks it so it can't be
  # reused. The one-time token is retained so a re-scan shows an "already used"
  # warning (with time) rather than "not found".
  def mark_used!(outlet:, staff:)
    update!(state: "used", used_at: Time.current, used_outlet: outlet, used_by_staff: staff)
  end

  def self.fresh_use_token(workspace)
    loop do
      token = format("%010d", SecureRandom.random_number(10**10))
      break token unless where(workspace_id: workspace.id, redeem_token: token).exists?
    end
  end

  def formatted_use_token
    redeem_token&.gsub(/(\d{3})(\d{3})(\d{4})/, '\1 \2 \3')
  end

  private

  def assign_code
    return if code.present?
    prefix = workspace&.subdomain.to_s[0, 2].upcase
    loop do
      c = "#{prefix}#{SecureRandom.alphanumeric(6).upcase}"
      break (self.code = c) unless Voucher.unscoped.exists?(workspace_id: workspace_id, code: c)
    end
  end
end
