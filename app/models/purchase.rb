class Purchase < ApplicationRecord
  acts_as_tenant(:workspace)

  SOURCES = %w[staff_scan pos_scan manual].freeze

  belongs_to :workspace
  belongs_to :member
  belongs_to :outlet, optional: true
  belongs_to :staff, class_name: "User", optional: true
  has_many :point_transactions, as: :source, dependent: :nullify

  validates :amount, numericality: { greater_than: 0 }
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc) }
end
