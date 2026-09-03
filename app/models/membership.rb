class Membership < ApplicationRecord
  ROLES = %w[owner manager staff cashier].freeze

  belongs_to :user
  belongs_to :workspace
  belongs_to :outlet, optional: true

  validates :role,   inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id }

  # Capability model (lightweight). Owners/managers manage everything; staff &
  # cashiers are limited to the counter scanner + customer lookup.
  def owner?   = role == "owner"
  def manager? = role == "manager"
  def admin?   = owner? || manager?

  def can_manage?
    admin?
  end

  def can_scan?
    true # every role can operate the counter scanner
  end

  def label = I18n.t("merchant.roles.#{role}", default: role)
end
