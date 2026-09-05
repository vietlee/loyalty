class AddShareAndBannerToCampaigns < ActiveRecord::Migration[7.2]
  def change
    add_column :campaigns, :share_slug, :string
    add_index  :campaigns, :share_slug, unique: true

    # Link a push broadcast back to the campaign it announced (auditability).
    add_reference :broadcasts, :campaign, foreign_key: true, null: true
  end
end
