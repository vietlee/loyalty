require "sidekiq"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Daily maintenance (voucher/point expiry + tier recompute) via sidekiq-cron.
  config.on(:startup) do
    schedule = {
      "daily_maintenance"    => { "cron" => "0 3 * * *", "class" => "MaintenanceJob", "queue" => "default" },
      "daily_billing_renewal" => { "cron" => "30 3 * * *", "class" => "BillingRenewalJob", "queue" => "default" },
      "deliver_scheduled_broadcasts" => { "cron" => "*/5 * * * *", "class" => "BroadcastDeliveryJob", "queue" => "default" }
    }
    if defined?(Sidekiq::Cron::Job)
      Sidekiq::Cron::Job.load_from_hash(schedule)
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
