class Mission < ApplicationRecord
  acts_as_tenant(:workspace)

  TYPES = %w[checkin spend visit refer].freeze
  PERIODS = %w[daily weekly].freeze

  belongs_to :workspace
  has_many :mission_progresses, dependent: :destroy

  validates :title, presence: true
  validates :mission_type, inclusion: { in: TYPES }
  validates :period, inclusion: { in: PERIODS }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  def display_icon = icon.presence || { "checkin" => "📍", "spend" => "💳", "visit" => "🏪", "refer" => "🤝" }[mission_type]

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
