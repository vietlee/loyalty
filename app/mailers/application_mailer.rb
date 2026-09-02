class ApplicationMailer < ActionMailer::Base
  default from: %(Dynamic Loyalty <#{ENV.fetch("MAIL_FROM", "no-reply@loyalty.czin.net")}>)
  layout "mailer"
end
