class AddAudienceFilterToBroadcasts < ActiveRecord::Migration[7.2]
  def change
    # Persist the exact filtered audience a broadcast was composed for, so the
    # recipient set matches what the merchant saw on the Customers list (segment +
    # branch + search), including for scheduled broadcasts delivered later.
    add_column :broadcasts, :audience_label, :string
    add_column :broadcasts, :audience_outlet_id, :bigint
    add_column :broadcasts, :audience_query, :string
  end
end
