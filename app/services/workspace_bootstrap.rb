# Sets up sensible defaults for a freshly created workspace (program, tiers,
# lucky wheel) so the merchant dashboard and customer app work immediately.
module WorkspaceBootstrap
  module_function

  TIERS = [
    { key: "bronze",  name: "Đồng",      threshold_points: 0,     multiplier: 1.0, from: "#C08A52", to: "#8A5A2E" },
    { key: "silver",  name: "Bạc",       threshold_points: 2000,  multiplier: 1.2, from: "#C9CDD4", to: "#8A9099" },
    { key: "gold",    name: "Vàng",      threshold_points: 5000,  multiplier: 1.5, from: "#E6C15A", to: "#B8892E" },
    { key: "diamond", name: "Kim Cương", threshold_points: 12000, multiplier: 2.0, from: "#8FD6E8", to: "#4A9FC7" }
  ].freeze

  EARN = { "fnb" => 10_000, "retail" => 15_000, "service" => 20_000 }.freeze

  def call(workspace)
    ActsAsTenant.with_tenant(workspace) do
      program = workspace.loyalty_program || workspace.build_loyalty_program
      program.update!(points_enabled: true, tiers_enabled: true,
                      stamps_enabled: workspace.industry == "fnb",
                      gamification_enabled: workspace.industry != "service",
                      earn_points: 1, earn_per_amount: EARN[workspace.industry] || 10_000,
                      currency: "VND", scan_mode: "staff_scans_member")

      TIERS.each_with_index do |t, i|
        next if workspace.tiers.exists?(key: t[:key])
        workspace.tiers.create!(name: t[:name], key: t[:key], threshold_points: t[:threshold_points],
                                multiplier: t[:multiplier], gradient_from: t[:from], gradient_to: t[:to], position: i)
      end

      if program.gamification_enabled && workspace.spin_wheel.nil?
        workspace.create_spin_wheel!(segments: SpinWheel::DEFAULT_SEGMENTS.map(&:stringify_keys),
                                     daily_free: true, cost_points: 100, active: true)
      end
    end
    workspace
  end
end
