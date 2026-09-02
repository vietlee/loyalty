class AddPointsExpiryToPrograms < ActiveRecord::Migration[7.2]
  def change
    add_column :loyalty_programs, :points_expiry_months, :integer, null: false, default: 0
  end
end
