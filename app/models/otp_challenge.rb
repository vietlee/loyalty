class OtpChallenge < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace

  TTL = 5.minutes
  MAX_ATTEMPTS = 5

  validates :phone, :code, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  # Issue (or re-issue) an OTP for a phone. Delivers via the configured provider
  # (Zalo ZNS); when none is configured the code is shown on-screen instead.
  def self.issue!(workspace:, phone:, purpose: "login")
    code = format("%06d", SecureRandom.random_number(1_000_000))
    challenge = create!(workspace: workspace, phone: phone.to_s, purpose: purpose,
                        code: code, expires_at: TTL.from_now)
    if OtpSender.configured?
      Rails.logger.info("[OTP] workspace=#{workspace.subdomain} phone=#{phone} (sent via provider)")
      OtpDeliveryJob.perform_later(phone.to_s, code)
    else
      Rails.logger.info("[OTP] workspace=#{workspace.subdomain} phone=#{phone} code=#{code} (on-screen)")
    end
    challenge
  end

  def verify(input)
    return :expired if expires_at < Time.current || consumed_at.present?
    increment!(:attempts)
    return :too_many if attempts > MAX_ATTEMPTS
    return :mismatch unless ActiveSupport::SecurityUtils.secure_compare(code, input.to_s)
    update!(consumed_at: Time.current)
    :ok
  end
end
