# Store check-in: a member proves they're on-site by scanning the merchant's
# printed check-in QR. The QR carries a signed, non-expiring workspace token
# (static poster). One check-in per member per day completes any active
# "checkin" missions and awards their points.
module Checkin
  module_function

  def verifier
    Rails.application.message_verifier("loyalty/checkin")
  end

  # Static token (no expiry) so a printed poster keeps working — until the
  # merchant rotates the nonce, which revokes every older poster.
  def encode(workspace)
    verifier.generate({ "w" => workspace.id, "n" => workspace.checkin_nonce })
  end

  # Valid only for this workspace AND the CURRENT nonce (old/rotated tokens fail).
  def valid?(token, workspace:)
    data = verifier.verify(token.to_s)
    data.is_a?(Hash) && data["w"].to_i == workspace.id &&
      data["n"].to_s == workspace.checkin_nonce.to_s
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

  # Complete today's check-in for the member. Returns [status, points_awarded]:
  #   :none    — workspace has no active check-in mission
  #   :already — the member already checked in today
  #   :done    — checked in (missions advanced, points awarded)
  def check_in!(member, workspace)
    missions = workspace.missions.active.where(mission_type: "checkin").to_a
    return [:none, 0] if missions.empty?
    return [:already, 0] if member.last_checkin_at&.to_date == Date.current

    points = 0
    member.update!(last_checkin_at: Time.current)
    missions.each do |m|
      mp = m.progress_for(member)
      mp.save! if mp.new_record?
      next if mp.completed?
      mp.advance!(1)
      points += m.reward_points if mp.completed?
    end
    [:done, points]
  end
end
