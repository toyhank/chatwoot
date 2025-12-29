class ResendEmailService
  RESEND_API_URL = 'https://api.resend.com/emails'.freeze

  def self.send_verification_code(email, code, expire_minutes = 5)
    new.send_verification_code(email, code, expire_minutes)
  end

  def send_verification_code(email, code, expire_minutes = 5)
    api_key = ENV['RESEND_API_KEY']
    from_email = ENV.fetch('RESEND_FROM_EMAIL', 'support@aichat2pic.com')

    unless api_key.present?
      raise ArgumentError, 'RESEND_API_KEY 环境变量未设置'
    end

    html_body = build_html_body(code, expire_minutes)
    text_body = build_text_body(code, expire_minutes)

    payload = {
      from: from_email,
      to: email,
      subject: '您的注册验证码',
      html: html_body,
      text: text_body
    }

    headers = {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json'
    }

    response = RestClient.post(RESEND_API_URL, payload.to_json, headers)

    result = JSON.parse(response.body)
    Rails.logger.info("Resend email sent successfully. Email ID: #{result['id']}, To: #{email}")

    {
      success: true,
      email_id: result['id'],
      to: email
    }
  rescue RestClient::ExceptionWithResponse => e
    error_message = parse_error_message(e)
    Rails.logger.error("Resend email failed: #{error_message}")
    {
      success: false,
      error: error_message
    }
  rescue StandardError => e
    Rails.logger.error("Resend email error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    {
      success: false,
      error: e.message
    }
  end

  private

  def build_html_body(code, expire_minutes)
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>注册验证码</title>
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
            <h2 style="color: #2d8cf0; margin-top: 0;">注册验证码</h2>
            <p>您好，</p>
            <p>您正在注册账号，验证码如下：</p>
            <div style="background-color: #fff; border: 2px dashed #2d8cf0; padding: 20px; text-align: center; margin: 20px 0; border-radius: 4px;">
              <span style="font-size: 32px; font-weight: bold; color: #2d8cf0; letter-spacing: 5px;">#{code}</span>
            </div>
            <p>验证码有效期为#{expire_minutes}分钟，请及时使用。</p>
            <p style="color: #999; font-size: 12px; margin-top: 30px;">如果您没有进行此操作，请忽略此邮件。</p>
          </div>
        </body>
      </html>
    HTML
  end

  def build_text_body(code, expire_minutes)
    <<~TEXT
      注册验证码

      您好，

      您正在注册账号，验证码如下：

      #{code}

      验证码有效期为#{expire_minutes}分钟，请及时使用。

      如果您没有进行此操作，请忽略此邮件。
    TEXT
  end

  def parse_error_message(exception)
    return exception.message unless exception.response

    begin
      error_data = JSON.parse(exception.response.body)
      error_data['message'] || exception.message
    rescue JSON::ParserError
      exception.message
    end
  end
end

