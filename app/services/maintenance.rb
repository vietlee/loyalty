# Periodic housekeeping run daily by MaintenanceJob (sidekiq-cron):
#   - expire vouchers past their validity window
#   - recompute cached points/tier for every member (handles cycle roll-off)
# Cross-tenant — always runs without a tenant scope.
module Maintenance
  module_function

  def run_all
    { vouchers_expired: expire_vouchers, members_recomputed: recompute_members }
  end

  def expire_vouchers
    n = ActsAsTenant.without_tenant do
      Voucher.where(state: "active")
             .where("expires_at IS NOT NULL AND expires_at < ?", Time.current)
             .update_all(state: "expired", updated_at: Time.current)
    end
    Rails.logger.info("[Maintenance] expired #{n} vouchers")
    n
  end

  def recompute_members
    count = 0
    ActsAsTenant.without_tenant do
      Member.includes(:workspace).find_each do |member|
        ActsAsTenant.with_tenant(member.workspace) { member.recompute_points! }
        count += 1
      end
    end
    Rails.logger.info("[Maintenance] recomputed #{count} members")
    count
  end
end
