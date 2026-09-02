class Rating < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member
  belongs_to :outlet, optional: true

  validates :stars, inclusion: { in: 1..5 }
  validates :member_id, uniqueness: { scope: :workspace_id }

  scope :recent, -> { order(created_at: :desc) }
end
