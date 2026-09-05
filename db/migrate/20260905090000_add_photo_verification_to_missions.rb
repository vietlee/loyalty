class AddPhotoVerificationToMissions < ActiveRecord::Migration[7.2]
  def change
    # Per-mission proof config (e.g. points per social platform for social_share).
    add_column :missions, :proof_config, :jsonb, default: {}, null: false

    # Photo-proof submission state on each member's mission progress.
    add_column :mission_progresses, :approval_status, :string
    add_column :mission_progresses, :submitted_at, :datetime
    add_column :mission_progresses, :platform, :string
    add_column :mission_progresses, :note, :text
    add_column :mission_progresses, :ai_verdict, :jsonb, default: {}, null: false
    add_column :mission_progresses, :reviewed_at, :datetime
    add_column :mission_progresses, :reviewed_by_id, :bigint

    add_index :mission_progresses, :approval_status
  end
end
