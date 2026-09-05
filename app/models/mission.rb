class Mission < ApplicationRecord
  acts_as_tenant(:workspace)

  TYPES = %w[checkin spend visit refer review social_share].freeze
  # Mission types completed by submitting a photo for review (manual or AI).
  PHOTO_PROOF_TYPES = %w[review social_share].freeze
  PROOF_PLATFORMS = %w[facebook instagram tiktok zalo].freeze
  PLATFORM_LABELS = {
    "facebook" => "Facebook", "instagram" => "Instagram",
    "tiktok" => "TikTok", "zalo" => "Zalo"
  }.freeze
  PERIODS = %w[daily weekly].freeze

  belongs_to :workspace
  has_many :mission_progresses, dependent: :destroy

  validates :title, presence: true
  validates :mission_type, inclusion: { in: TYPES }
  validates :period, inclusion: { in: PERIODS }
  # Photo-proof missions are single-submission, not incremental counters.
  validates :goal, inclusion: { in: [1] }, if: :photo_proof?

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  def photo_proof? = mission_type.in?(PHOTO_PROOF_TYPES)

  # Points awarded for a completion. social_share can pay per-platform via
  # proof_config["platforms"][platform]; everything else uses the flat rate.
  def points_for(platform = nil)
    per = platform && proof_config.dig("platforms", platform.to_s)
    per.present? ? per.to_i : reward_points
  end

  def display_icon
    icon.presence || {
      "checkin" => "📍", "spend" => "💳", "visit" => "🏪", "refer" => "🤝",
      "review" => "⭐", "social_share" => "📣"
    }[mission_type]
  end

  # Current period bucket key (auto-resets progress each day/week).
  def current_period_key(time = Time.current)
    period == "weekly" ? time.strftime("%G-W%V") : time.strftime("%Y-%m-%d")
  end

  def progress_for(member)
    mission_progresses.find_or_initialize_by(member: member, period_key: current_period_key) do |mp|
      mp.workspace = workspace
    end
  end
end
