class AddReplyToRatings < ActiveRecord::Migration[7.2]
  def change
    add_column :ratings, :reply_body, :text
    add_column :ratings, :replied_at, :datetime
    add_reference :ratings, :replied_by, foreign_key: { to_table: :users }
  end
end
