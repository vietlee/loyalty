class OtpChallenge < ApplicationRecord
  acts_as_tenant(:workspace)

  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  belongs_to :workspace

  validates :email, :code, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  # Issue (or re-issue) a login OTP for an email. Delivers by email when a mailer
  # is configured; otherwise the code is shown on-screen (dev / not-yet-configured).
  def self.issue!(workspace:, email:, purpose: "login")
    code = format("%06d", SecureRandom.random_number(1_000_000))
    challenge = create!(workspace: workspace, email: email.to_s.strip.downcase,
                        purpose: purpose, code: code, expires_at: TTL.from_now)
    if EmailOtp.configured?
      OtpMailer.login_code(challenge).deliver_later
      Rails.logger.info("[OTP] workspace=#{workspace.subdomain} email=#{email} (emailed)")
    else
      Rails.logger.info("[OTP] workspace=#{workspace.subdomain} email=#{email} code=#{code} (on-screen)")
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
