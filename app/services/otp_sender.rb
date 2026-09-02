# Pluggable OTP delivery. Today it dispatches to Zalo ZNS; swap/add providers
# here. When no provider is configured, delivery is a no-op and the OTP is shown
# on-screen instead (see Customer::SessionsController#show_otp_onscreen?).
module OtpSender
  module_function

  def configured?
    ZaloZns.configured?
  end

  def deliver(phone:, code:)
    return false unless configured?
    ZaloZns.new.deliver(phone: phone, code: code)
  end
end
