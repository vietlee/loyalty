class OtpMailer < ApplicationMailer
  def login_code(challenge)
    @code = challenge.code
    @workspace = challenge.workspace
    mail(to: challenge.email,
         from: ENV.fetch("MAIL_FROM", "no-reply@loyalty.czin.net"),
         subject: "#{@workspace.name}: Mã đăng nhập #{@code}")
  end
end
