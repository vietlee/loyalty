class AddRewardPointsToBadges < ActiveRecord::Migration[7.2]
  def change
    add_column :badges, :reward_points, :integer, default: 0, null: false
  end
end
