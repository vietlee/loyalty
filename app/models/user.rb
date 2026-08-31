class User < ApplicationRecord
  # Merchant staff / owner. Belongs to workspaces via memberships.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  LOCALES = %w[vi en].freeze

  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships

  validates :name, presence: true
  validates :locale, inclusion: { in: LOCALES }

  def membership_for(workspace)
    return nil unless workspace
    memberships.find { |m| m.workspace_id == workspace.id } ||
      memberships.find_by(workspace_id: workspace.id)
  end

  def display_locale
    LOCALES.include?(locale) ? locale : "vi"
  end

  def initials
    name.to_s.split.map { |w| w[0] }.first(2).join.upcase.presence || email[0, 2].upcase
  end
end
