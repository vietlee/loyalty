class Campaign < ApplicationRecord
  acts_as_tenant(:workspace)

  TYPES = %w[promo_voucher double_points happy_hour event flash_mission].freeze
  STATUSES = %w[draft scheduled running paused ended].freeze
  AUDIENCES = %w[all vip new at_risk birthday].freeze

  belongs_to :workspace
  belongs_to :reward, optional: true
  has_many :promo_codes, dependent: :destroy

  validates :name, presence: true
  validates :campaign_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  TYPE_LABELS = {
    "promo_voucher" => "Phát voucher (QR)", "double_points" => "Nhân đôi điểm",
    "happy_hour" => "Giờ vàng", "event" => "Sự kiện", "flash_mission" => "Nhiệm vụ chớp nhoáng"
  }.freeze
  AUDIENCE_LABELS = {
    "all" => "Tất cả khách", "vip" => "Khách VIP", "new" => "Khách mới",
    "at_risk" => "Sắp rời bỏ", "birthday" => "Sinh nhật"
  }.freeze

  def type_label     = I18n.t("merchant.campaign_types.#{campaign_type}", default: TYPE_LABELS[campaign_type])
  def audience_label = I18n.t("merchant.campaign_audiences.#{audience}", default: AUDIENCE_LABELS[audience])
  def content_value(key) = content.presence&.dig(key.to_s)

  def live?
    status == "running" &&
      (starts_at.nil? || starts_at <= Time.current) &&
      (ends_at.nil? || ends_at >= Time.current)
  end

  def status_label = I18n.t("merchant.campaign_statuses.#{status}", default: status)
end
