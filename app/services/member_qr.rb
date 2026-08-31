# Short-lived signed token identifying a member for counter scanning (§6.1).
# The token auto-expires so a screenshot can't be reused later at another till.
module MemberQr
  TTL = 45 # seconds

  def self.verifier
    Rails.application.message_verifier("loyalty/member_qr")
  end

  def self.encode(member)
    verifier.generate({ "m" => member.id, "w" => member.workspace_id },
                      expires_in: TTL.seconds)
  end

  # Returns the member if the token is valid, unexpired, and matches the given
  # workspace (tenant isolation). Nil otherwise.
  def self.decode(token, workspace:)
    data = verifier.verify(token.to_s)
    return nil unless data && data["w"].to_i == workspace.id
    Member.find_by(id: data["m"])
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageVerifier::ExpiredMessage
    nil
  end
end
