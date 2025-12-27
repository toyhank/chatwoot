class Api::Mobile::Register::RegisterController < Api::BaseController
  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     raise: false

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP
  MAX_DAILY_CODE_COUNT = 10
  CODE_EXPIRE_MINUTES = 5
  CODE_RESEND_INTERVAL = 60 # seconds

  # GET /api/mobile/register/check_email
  def check_email
    email = params[:email]&.strip

    unless valid_email?(email)
      return render_error(status: 400, msg: '邮箱地址格式不正确')
    end

    email = email.downcase
    user = User.from_email(email)
    available = user.nil?

    render_success(
      data: {
        email: email,
        available: available,
        message: available ? '该邮箱可以使用' : '该邮箱已被注册'
      }
    )
  end

  # POST /api/mobile/register/send_code
  def send_code
    email = params[:email]&.strip

    unless valid_email?(email)
      return render_error(status: 400, msg: '邮箱地址格式不正确')
    end

    email = email.downcase

    # 检查邮箱是否已被注册
    if User.exists?(email: email)
      return render_error(status: 400, msg: '该邮箱已被注册')
    end

    # 检查今日发送次数
    if EmailVerificationCode.send_count_today(email) >= MAX_DAILY_CODE_COUNT
      return render_error(status: 400, msg: '今日发送次数已达上限')
    end

    # 检查发送间隔
    unless EmailVerificationCode.can_send?(email)
      return render_error(status: 400, msg: '发送过于频繁，请60秒后再试')
    end

    # 生成并发送验证码
    verification_code = EmailVerificationCode.generate_for_email(email)
    begin
      RegisterMailer.verification_code(email, verification_code.code, CODE_EXPIRE_MINUTES).deliver_now
    rescue StandardError => mail_error
      Rails.logger.warn("Failed to send email (continuing anyway): #{mail_error.message}")
      # 在开发环境中，即使邮件发送失败也继续，验证码已经保存到数据库
    end

    render_success(
      data: {
        email: email,
        expire: CODE_EXPIRE_MINUTES * 60,
        message: '验证码已发送到您的邮箱，请注意查收'
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to send verification code: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render_error(status: 500, msg: '发送验证码失败，请稍后重试')
  end

  # POST /api/mobile/register/register
  def register
    email = params[:email]&.strip
    code = params[:code]&.strip
    password = params[:password]
    nickname = params[:nickname]&.strip
    phone = params[:phone]&.strip
    appid = params[:appid]&.strip

    # 验证邮箱格式
    unless valid_email?(email)
      return render_error(status: 400, msg: '邮箱地址格式不正确')
    end

    email = email.downcase

    # 检查邮箱是否已被注册
    if User.exists?(email: email)
      return render_error(status: 400, msg: '该邮箱已被注册')
    end

    # 验证验证码
    unless EmailVerificationCode.valid_code?(email, code)
      return render_error(status: 400, msg: '验证码错误或已过期')
    end

    # 验证密码
    if password.blank? || password.length < 6 || password.length > 20
      return render_error(status: 400, msg: '密码长度必须在6-20个字符之间')
    end

    # 创建用户
    user_name = nickname.presence || email.split('@').first

    ActiveRecord::Base.transaction do
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        name: user_name,
        confirmed_at: Time.current
      )

      # 标记验证码为已使用
      EmailVerificationCode.mark_as_used(email, code)

      render_success(
        data: {
          uid: user.id,
          email: user.email,
          nickname: user.name,
          message: '注册成功'
        }
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error(status: 400, msg: e.record.errors.full_messages.join(', '))
  rescue StandardError => e
    Rails.logger.error("Registration failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render_error(status: 500, msg: '注册失败，请稍后重试')
  end

  # POST /api/mobile/register/login
  def login
    email = params[:email]&.strip
    password = params[:password]

    # 验证邮箱格式
    unless valid_email?(email)
      return render_error(status: 400, msg: '邮箱地址格式不正确')
    end

    if password.blank?
      return render_error(status: 400, msg: '密码不能为空')
    end

    email = email.downcase
    user = User.from_email(email)

    unless user&.valid_password?(password)
      return render_error(status: 400, msg: '邮箱或密码错误')
    end

    unless user.active_for_authentication?
      return render_error(status: 400, msg: '账户已被禁用')
    end

    # 返回用户信息
    render_success(
      data: {
        uid: user.id,
        email: user.email,
        nickname: user.name,
        avatar: user.avatar_url || '/statics/default_avatar.png',
        phone: '',
        message: '登录成功'
      }
    )
  rescue StandardError => e
    Rails.logger.error("Login failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render_error(status: 500, msg: '登录失败，请稍后重试')
  end

  private

  def valid_email?(email)
    email.present? && email.match?(EMAIL_REGEX)
  end

  def render_success(data: {}, msg: 'ok')
    render json: {
      status: 200,
      msg: msg,
      data: data
    }, status: :ok
  end

  def render_error(status: 400, msg: '')
    render json: {
      status: status,
      msg: msg
    }, status: status
  end
end

