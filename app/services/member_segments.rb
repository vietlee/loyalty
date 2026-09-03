# Preset customer segments for CRM targeting. Each returns a tenant-scoped
# Member relation (call within ActsAsTenant.with_tenant / a scoped request).
module MemberSegments
  module_function

  PRESETS = {
    "all"      => { label: "Tất cả khách",       icon: "👥" },
    "vip"      => { label: "Khách VIP",           icon: "👑" },
    "at_risk"  => { label: "Sắp rời bỏ (>30 ngày)", icon: "⚠️" },
    "new"      => { label: "Khách mới trong tuần", icon: "✨" },
    "birthday" => { label: "Sinh nhật tháng này",  icon: "🎂" }
  }.freeze

  def label(key) = I18n.t("merchant.segments.#{key}", default: (PRESETS.dig(key, :label) || "Tất cả khách"))
  def icon(key)  = PRESETS.dig(key, :icon) || "👥"

  def resolve(key)
    case key
    when "vip"      then vip
    when "at_risk"  then at_risk
    when "new"      then new_members
    when "birthday" then birthday
    else Member.all
    end
  end

  def vip
    Member.where(tier_key: %w[gold diamond])
  end

  def new_members
    Member.where("created_at >= ?", 7.days.ago)
  end

  def birthday
    Member.where.not(birthday: nil).where("EXTRACT(MONTH FROM birthday) = ?", Date.current.month)
  end

  # No purchase in the last 30 days, but has purchased before.
  def at_risk
    active_ids = Purchase.where("created_at >= ?", 30.days.ago).distinct.pluck(:member_id)
    ever_ids   = Purchase.distinct.pluck(:member_id)
    Member.where(id: ever_ids - active_ids)
  end

  def counts
    PRESETS.keys.index_with { |k| resolve(k).count }
  end
end
