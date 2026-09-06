class AddRewardToBadges < ActiveRecord::Migration[7.2]
  # A badge can reward bonus points and/or hand the member a voucher (ưu đãi).
  def change
    add_reference :badges, :reward, foreign_key: true, null: true
  end
end
