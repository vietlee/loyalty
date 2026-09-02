class OtpDeliveryJob < ApplicationJob
  queue_as :default

  def perform(phone, code)
    OtpSender.deliver(phone: phone, code: code)
  end
end
