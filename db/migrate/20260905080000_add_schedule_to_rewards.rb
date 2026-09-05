class AddScheduleToRewards < ActiveRecord::Migration[7.2]
  # Recurring availability rules: { "days" => [1,2,..7], "from_hour" => 8, "to_hour" => 17 }
  # (empty = always, within the starts_at/ends_at window).
  def change
    add_column :rewards, :schedule, :jsonb, default: {}, null: false
  end
end
