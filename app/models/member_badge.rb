class MemberBadge < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member
  belongs_to :badge

  validates :member_id, uniqueness: { scope: :badge_id }
end
