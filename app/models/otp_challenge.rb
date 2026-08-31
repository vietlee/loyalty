class OtpChallenge < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace

  TTL = 5.minutes
  MAX_ATTEMPTS = 5

  validates :phone, :code, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  # Issue (or re-issue) an OTP for a phone. In dev the code is returned to the
  # caller and logged; a real SMS/Zalo provider swaps in here later.
  def self.issue!(workspace:, phone:, purpose: "login")
    code = format("%06d", SecureRandom.random_number(1_000_000))
    challenge = create!(workspace: workspace, phone: phone.to_s, purpose: purpose,
                        code: code, expires_at: TTL.from_now)
    Rails.logger.info("[OTP] workspace=#{workspace.subdomain} phone=#{phone} code=#{code}")
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
