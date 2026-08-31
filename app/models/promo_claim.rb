class PromoClaim < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :promo_code
  belongs_to :member
  belongs_to :voucher, optional: true

  validates :member_id, uniqueness: { scope: :promo_code_id }
end
