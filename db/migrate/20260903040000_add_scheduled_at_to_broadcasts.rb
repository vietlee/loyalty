class AddScheduledAtToBroadcasts < ActiveRecord::Migration[7.2]
  def change
    add_column :broadcasts, :scheduled_at, :datetime
    add_index :broadcasts, :scheduled_at
  end
end
