class Outlet < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  has_many :memberships, dependent: :nullify

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
