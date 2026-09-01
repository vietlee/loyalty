class PushSubscription < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member

  validates :endpoint, :p256dh, :auth, presence: true

  # Upsert by endpoint (a device re-subscribing keeps one row).
  def self.store!(member:, endpoint:, p256dh:, auth:)
    sub = find_or_initialize_by(member: member, endpoint: endpoint)
    sub.workspace = member.workspace
    sub.update!(p256dh: p256dh, auth: auth)
    sub
  end
end
