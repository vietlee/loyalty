class AddAudienceTierToBroadcasts < ActiveRecord::Migration[7.2]
  # Broadcasts can now also be narrowed to a membership tier (matches the
  # Customers list "Hạng" filter), persisted so scheduled sends honor it too.
  def change
    add_column :broadcasts, :audience_tier, :string
  end
end
