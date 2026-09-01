class Broadcast < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :created_by, class_name: "User", optional: true
  has_many :notifications, dependent: :nullify

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Fan out an in-app notification to every member in the segment.
  def deliver!(members)
    now = Time.current
    rows = members.map do |m|
      { workspace_id: workspace_id, member_id: m.id, broadcast_id: id,
        title: title, body: body, kind: "promo", created_at: now, updated_at: now }
    end
    Notification.insert_all(rows) if rows.any?
    update!(sent_count: rows.size, sent_at: now)
    # Push to installed PWAs (in-app inbox is populated above regardless).
    PushJob.perform_later(workspace_id, members.map(&:id), title, body.to_s, "/notifications") if rows.any?
  end
end
