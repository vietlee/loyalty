class ForcePhotoProofMissionsOnce < ActiveRecord::Migration[7.2]
  # Photo-proof missions (review / social_share) are now one-time only. Bring any
  # existing rows (created while daily/weekly was allowed) in line.
  def up
    execute "UPDATE missions SET period = 'once' WHERE mission_type IN ('review', 'social_share')"
  end

  def down
    # No-op: 'daily' was an arbitrary previous default; nothing meaningful to restore.
  end
end
