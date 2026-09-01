class AddLastCheckinAtToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :last_checkin_at, :datetime
  end
end
