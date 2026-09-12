class Purchase < ApplicationRecord
  acts_as_tenant(:workspace)

  SOURCES = %w[staff_scan pos_scan manual].freeze

  # How long the cashier who rang a bill up may undo it themselves. After this
  # a manager/owner still can — so a late-evening mistake is never stuck, but a
  # cashier can't quietly erase yesterday's takings.
  SELF_VOID_WINDOW = 30.minutes

  belongs_to :workspace
  belongs_to :member
  belongs_to :outlet, optional: true
  belongs_to :staff, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  has_many :point_transactions, as: :source, dependent: :nullify

  validates :amount, numericality: { greater_than: 0 }
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc) }
  # A voided bill never counts toward revenue, visits, tiers or segments. Every
  # reporting query goes through this scope — see VoidPurchase.
  scope :not_voided, -> { where(voided_at: nil) }
  scope :voided,     -> { where.not(voided_at: nil) }

  def voided? = voided_at.present?

  # Who may undo this bill: any manager/owner, or the cashier who created it
  # while it's still fresh.
  def voidable_by?(user, membership)
    return false if voided?
    return true  if membership&.can_manage?
    staff_id.present? && staff_id == user&.id && created_at > SELF_VOID_WINDOW.ago
  end
end
