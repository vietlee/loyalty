class AddExpiresAtToRewards < ActiveRecord::Migration[7.2]
  def change
    # Optional fixed expiry for issued vouchers. When set, an issued voucher
    # expires on this date; otherwise it expires valid_days after being claimed.
    add_column :rewards, :expires_at, :datetime
  end
end
