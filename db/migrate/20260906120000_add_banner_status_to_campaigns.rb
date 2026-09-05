class AddBannerStatusToCampaigns < ActiveRecord::Migration[7.2]
  def change
    add_column :campaigns, :banner_status, :string
    add_column :campaigns, :banner_requested_at, :datetime
  end
end
