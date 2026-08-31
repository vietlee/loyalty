class Referral < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :referrer, class_name: "Member"
  belongs_to :referred, class_name: "Member"

  validates :referred_id, uniqueness: true

  scope :completed, -> { where(state: "completed") }
  scope :pending,   -> { where(state: "pending") }

  def completed? = state == "completed"
end
