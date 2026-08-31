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
  def status_label = STATUS_LABELS[status]
  def monthly_price = active? ? PLAN_PRICES[plan].to_i : 0

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
