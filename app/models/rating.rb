class Rating < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member
  belongs_to :outlet, optional: true
  belongs_to :replied_by, class_name: "User", optional: true

  validates :stars, inclusion: { in: 1..5 }

  scope :recent,     -> { order(created_at: :desc) }
  scope :unanswered, -> { where(replied_at: nil) }
  scope :low,        -> { where("stars <= 3") }

  def replied? = replied_at.present?
  def low?     = stars <= 3
end
