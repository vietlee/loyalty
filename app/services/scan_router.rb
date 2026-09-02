# Disambiguates a scanned code so the counter scanner works regardless of which
# tab staff are on. The two token shapes are unmistakable:
#   * member personal QR — a signed MessageVerifier string (letters + "--")
#   * reward use-code     — a 10-digit numeric voucher token
module ScanRouter
  module_function

  # The Voucher when the scanned token is a reward use-code, else nil.
  def reward_use_code(raw, workspace)
    s = raw.to_s.strip
    return nil if s.blank? || s.match?(/[A-Za-z]/) # signed member tokens have letters
    digits = s.gsub(/\D/, "")
    return nil unless digits.length >= 8            # use-codes are 10 digits
    Voucher.where(workspace_id: workspace.id, redeem_token: digits).first
  end

  # The Member when the scanned token is a personal member QR, else nil.
  def member(raw, workspace)
    return nil if raw.to_s.strip.blank?
    MemberQr.decode(raw, workspace: workspace)
  end
end
