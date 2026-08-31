class CreatePlans < ActiveRecord::Migration[7.2]
  def change
    create_table :plans do |t|
      t.string  :key,      null: false            # starter / growth / scale
      t.string  :name,     null: false
      t.integer :price,    null: false, default: 0 # VND / month
      t.integer :position, null: false, default: 0

      # Limits (nil = unlimited)
      t.integer :max_outlets
      t.integer :max_members

      # Feature gates
      t.boolean :allow_stamps,        null: false, default: true
      t.boolean :allow_gamification,  null: false, default: true
      t.boolean :allow_campaigns,     null: false, default: true
      t.boolean :allow_custom_domain, null: false, default: false
      t.boolean :allow_ab_testing,    null: false, default: false

      t.jsonb   :features, null: false, default: [] # display bullet list

      t.timestamps
    end
    add_index :plans, :key, unique: true
  end
end
