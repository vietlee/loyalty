class Broadcast < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :created_by, class_name: "User", optional: true
  has_many :notifications, dependent: :nullify

  validates :title, presence: true
  validates :body,  presence: true

  scope :recent, -> { order(created_at: :desc) }
  # Scheduled broadcasts whose time has arrived and haven't been sent.
  scope :due, -> { where(sent_at: nil).where.not(scheduled_at: nil).where("scheduled_at <= ?", Time.current) }

  def scheduled? = scheduled_at.present? && sent_at.nil?

  # Resolve the segment now and deliver (used by the scheduled-delivery job).
  def deliver_to_segment!
    deliver!(MemberSegments.resolve(segment_key).to_a)
  end

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
