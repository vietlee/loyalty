class CreateLoyaltyPrograms < ActiveRecord::Migration[7.2]
  def change
    create_table :loyalty_programs do |t|
      t.references :workspace, null: false, foreign_key: true, index: { unique: true }

      # Mechanism toggles (each workspace turns on what it needs)
      t.boolean :points_enabled,       null: false, default: true
      t.boolean :tiers_enabled,        null: false, default: true
      t.boolean :stamps_enabled,       null: false, default: false
      t.boolean :gamification_enabled, null: false, default: false

      # Earning
      t.integer :earn_points,   null: false, default: 1      # points granted per earn_per_amount
      t.integer :earn_per_amount, null: false, default: 10000 # currency units (e.g. 1 điểm / 10.000đ)
      t.string  :currency,      null: false, default: "VND"

      # Counter scan mode: staff_scans_member / member_scans_pos / both
      t.string  :scan_mode,     null: false, default: "staff_scans_member"

      # Tier cycle window in months (rolling accumulation)
      t.integer :tier_cycle_months, null: false, default: 12

      t.jsonb   :settings, null: false, default: {}

      t.timestamps
    end
  end
end
