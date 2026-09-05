# A cached, durable AI-generated insight for a workspace (one row per kind).
# Generated asynchronously so it never blocks a page load; the merchant sees
# `generated_at` and can refresh on demand.
class WorkspaceInsight < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace

  validates :kind, presence: true

  def generating? = status == "generating"
  def stale?(within: 1.day) = generated_at.nil? || generated_at < within.ago
end
