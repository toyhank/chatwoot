class RegisterMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')

  def verification_code(email, code, expire_minutes = 5)
    @email = email
    @code = code
    @expire_minutes = expire_minutes

    mail(
      to: @email,
      subject: '您的注册验证码'
    )
  end
end

