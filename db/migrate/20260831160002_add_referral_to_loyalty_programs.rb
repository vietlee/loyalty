class AddReferralToLoyaltyPrograms < ActiveRecord::Migration[7.2]
  def change
    change_table :loyalty_programs, bulk: true do |t|
      t.boolean :referral_enabled, null: false, default: true
      t.integer :referral_points,  null: false, default: 100 # awarded to each side
    end
  end
end
