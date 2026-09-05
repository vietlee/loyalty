class BackfillDefaultOutlets < ActiveRecord::Migration[7.2]
  # Every workspace must have at least one branch now (the check-in QR lives on
  # branches, not the workspace). Create a default "MAIN" branch for any shop
  # that has none, named after the shop.
  def up
    execute <<~SQL
      INSERT INTO outlets (workspace_id, code, name, active, created_at, updated_at)
      SELECT w.id, 'MAIN', w.name, true, now(), now()
      FROM workspaces w
      WHERE NOT EXISTS (SELECT 1 FROM outlets o WHERE o.workspace_id = w.id)
    SQL
  end

  def down; end
end
