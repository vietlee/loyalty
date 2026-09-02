class Workspace < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  INDUSTRIES = %w[fnb retail service].freeze
  STATUSES   = %w[pending trial active past_due suspended].freeze
  STATUS_LABELS = {
    "pending" => "Chờ duyệt", "trial" => "Dùng thử", "active" => "Đang hoạt động",
    "past_due" => "Quá hạn", "suspended" => "Tạm ngưng"
  }.freeze
  PLAN_PRICES = { "starter" => 199_000, "growth" => 499_000, "scale" => 1_290_000 }.freeze
  PLANS      = %w[starter growth scale].freeze

  has_one_attached :logo
  has_many :memberships, dependent: :destroy
  has_many :users,   through: :memberships
  has_many :outlets, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :tiers, -> { order(:position) }, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :promo_codes, dependent: :destroy
  has_many :pos_charges, dependent: :destroy
  has_many :stamp_cards, dependent: :destroy
  has_many :missions, dependent: :destroy
  has_many :badges, dependent: :destroy
  has_one  :spin_wheel, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :broadcasts, dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_one  :loyalty_program, dependent: :destroy

  validates :name, :subdomain, presence: true
  validates :subdomain, uniqueness: true, format: { with: /\A[a-z0-9][a-z0-9-]*\z/ }
  validates :industry, inclusion: { in: INDUSTRIES }
  validates :status,   inclusion: { in: STATUSES }

  before_validation :default_subdomain, on: :create

  # -- Program helpers -----------------------------------------------------
  def program
    loyalty_program || build_loyalty_program
  end

  def default_locale_sym
    %w[vi en].include?(locale_default) ? locale_default.to_sym : :vi
  end

  def active?  = status == "active"
  def trial?   = status == "trial"
  def pending? = status == "pending"
  def onboarded? = settings["onboarded"] == true

  # Version tag baked into the check-in QR token. Rotating it invalidates every
  # previously printed poster (so a leaked QR can be revoked). Lazily initialised.
  def checkin_nonce
    settings["checkin_nonce"].presence || rotate_checkin_nonce!
  end

  def rotate_checkin_nonce!
    nonce = SecureRandom.hex(8)
    update!(settings: settings.merge("checkin_nonce" => nonce))
    nonce
  end
  def status_label = STATUS_LABELS[status]

  # ---- Plan (limits & feature gates) ------------------------------------
  def plan_record
    @plan_record ||= Plan.for(plan)
  end

  def monthly_price = active? ? plan_record.price.to_i : 0

  def plan_allows?(feature)
    case feature.to_sym
    when :stamps        then plan_record.allow_stamps
    when :gamification  then plan_record.allow_gamification
    when :campaigns     then plan_record.allow_campaigns
    when :custom_domain then plan_record.allow_custom_domain
    when :ab_testing    then plan_record.allow_ab_testing
    else true
    end
  end

  def outlet_limit = plan_record.max_outlets
  def member_limit = plan_record.max_members

  # ---- Subscription / billing -------------------------------------------
  GRACE_DAYS = 10 # days after expiry before an unpaid workspace is locked out

  def subscription_active? = paid_until.present? && paid_until >= Time.current

  def subscription_days_left
    return nil if paid_until.nil?
    ((paid_until - Time.current) / 1.day).ceil
  end

  # Whole days the subscription is past due (nil if never paid or still active).
  def subscription_overdue_days
    return nil if paid_until.nil? || subscription_active?
    ((Time.current - paid_until) / 1.day).floor
  end

  # Why the workspace is locked out (nil = usable):
  #   :suspended — an operator suspended it → contact support to reopen
  #   :unpaid    — subscription expired more than GRACE_DAYS ago → pay to reopen
  def access_blocked_reason
    return :suspended if status == "suspended"
    d = subscription_overdue_days
    return :unpaid if d && d > GRACE_DAYS
    nil
  end

  def access_blocked? = access_blocked_reason.present?

  # The next unpaid billing month (starts when the current paid period ends).
  def next_billing_period
    start = subscription_active? ? paid_until.to_date : Date.current
    [start, start + 1.month - 1.day]
  end

  def can_add_outlet?(current = outlets.count)
    outlet_limit.nil? || current < outlet_limit
  end

  def can_add_member?(current = nil)
    return true if member_limit.nil?
    current ||= ActsAsTenant.with_tenant(self) { members.count }
    current < member_limit
  end

  # -- Theming (per-workspace white-label) ---------------------------------
  # Neutral defaults = the "Cozy Cafe" preset from the product mockup. Each
  # workspace overrides a handful of base tokens; the rest derive via CSS
  # color-mix in the token stylesheet + the _theme_vars partial.
  DEFAULT_THEME = {
    "primary"      => "#8C4A2F",  # warm brown
    "primary_2"    => "#E08A3C",  # orange accent
    "on_primary"   => "#FFF7EE",
    "surface"      => "#FBF6EF",  # cream
    "surface_2"    => "#F3E9DD",
    "ink"          => "#3A2A20",
    "ink_2"        => "#7A6656",
    "line"         => "#E7D9C9",
    "radius"       => "22px",
    "font_display" => "Fraunces",          # serif for big numerals
    "font_body"    => "Plus Jakarta Sans"
  }.freeze

  FONT_STACKS = {
    "Fraunces"           => '"Fraunces", Georgia, "Times New Roman", serif',
    "Playfair Display"   => '"Playfair Display", Georgia, serif',
    "Plus Jakarta Sans"  => '"Plus Jakarta Sans", ui-sans-serif, system-ui, sans-serif',
    "Inter"              => '"Inter", ui-sans-serif, system-ui, sans-serif',
    "Be Vietnam Pro"     => '"Be Vietnam Pro", ui-sans-serif, system-ui, sans-serif'
  }.freeze

  def theme_value(key)
    theme.presence&.dig(key.to_s).presence || DEFAULT_THEME[key.to_s]
  end

  # Radius as valid CSS: the appearance slider stores a bare number (e.g. "16"),
  # which is invalid for border-radius without a unit — append px.
  def css_radius
    r = theme_value(:radius).to_s.strip
    r.match?(/\A\d+(\.\d+)?\z/) ? "#{r}px" : (r.presence || "16px")
  end

  def resolved_theme
    DEFAULT_THEME.merge(theme.presence || {})
  end

  def font_stack(key)
    FONT_STACKS[theme_value(key)] || FONT_STACKS[DEFAULT_THEME[key]]
  end

  # -- Branding ------------------------------------------------------------
  DEFAULT_BRANDING = {
    "logo_text"     => nil,        # falls back to name initials
    "tagline"       => "Chương trình tri ân khách hàng",
    "customer_term" => "bạn",      # tone of voice: "bạn" / "quý khách" / "Fan cứng"
    "tone"          => "friendly"  # friendly / formal / youthful
  }.freeze

  def branding_value(key)
    branding.presence&.dig(key.to_s).presence || DEFAULT_BRANDING[key.to_s]
  end

  def logo_initials
    (branding_value("logo_text") || name).to_s.split.map { |w| w[0] }.first(2).join.upcase
  end

  private

  def default_subdomain
    self.subdomain = slug if subdomain.blank? && slug.present?
    self.subdomain ||= name.to_s.parameterize
  end
end
