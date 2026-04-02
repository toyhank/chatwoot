class Api::Mobile::AdminController < Api::BaseController
  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     raise: false

  # 以下接口需要认证
  before_action :authenticate_admin!, except: [:login]

  # POST /api/mobile/admin/login
  def login
    email = params[:email]&.strip&.downcase
    password = params[:password]

    admin = User.where(type: 'SuperAdmin').find_by(email: email)
    if admin&.valid_password?(password)
      # 确保具有 access_token
      token = admin.access_token&.token
      unless token
        admin.create_access_token
        token = admin.access_token.token
      end

      render json: {
        status: 200,
        msg: '登录成功',
        data: {
          token: token,
          email: admin.email,
          name: admin.name
        }
      }
    else
      render json: { status: 401, msg: '账号或密码错误' }, status: :unauthorized
    end
  end

  # GET /api/mobile/admin/stats
  def stats
    total_users = User.where(type: nil).count
    today_checkins = User.where(type: nil).where('last_check_in_at >= ?', Time.current.beginning_of_day).count
    total_balance = User.where(type: nil).sum(:balance)

    render json: {
      status: 200,
      msg: 'ok',
      data: {
        total_users: total_users,
        today_checkins: today_checkins,
        total_balance: total_balance || 0
      }
    }
  end

  # GET /api/mobile/admin/users
  def users
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i

    query = User.where(type: nil).order(created_at: :desc)
    
    if (params[:search].present?)
      search_term = "%#{params[:search]}%"
      query = query.where('email ILIKE ? OR name ILIKE ?', search_term, search_term)
    end

    total = query.count
    users_list = query.page(page).per(per_page)

    data = users_list.map do |u|
      {
        id: u.id,
        name: u.name.presence || u.display_name.presence || 'Unknown',
        email: u.email,
        phone: '--',
        balance: u.balance || 0,
        created_at: u.created_at.strftime('%Y-%m-%d %H:%M'),
        last_login: u.current_sign_in_at ? u.current_sign_in_at.strftime('%Y-%m-%d %H:%M') : '--',
        last_login_ip: u.current_sign_in_ip || '未知',
        status: '正常'
      }
    end

    render json: {
      status: 200,
      msg: 'ok',
      data: {
        total: total,
        page: page,
        per_page: per_page,
        users: data
      }
    }
  end

  # GET /api/mobile/admin/checkins
  def checkins
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 100).to_i

    query = User.where(type: nil).order(last_check_in_at: :desc, created_at: :desc)
    
    total = query.count
    users_list = query.page(page).per(per_page)

    data = users_list.map do |u|
      has_checked_in_today = u.last_check_in_at && u.last_check_in_at >= Time.current.beginning_of_day
      {
        id: u.id,
        name: u.name.presence || u.display_name.presence || 'Unknown',
        phone: '--',
        check_in_date: u.last_check_in_at ? u.last_check_in_at.strftime('%Y-%m-%d') : '--',
        check_in_time: u.last_check_in_at ? u.last_check_in_at.strftime('%H:%M:%S') : '--',
        amount_awarded: has_checked_in_today ? '₦ 5' : '₦ 0', # since our script adds 5
        consecutive_days: has_checked_in_today ? '1 天' : '0 天',
        status: has_checked_in_today ? '已签到' : '未签到'
      }
    end

    render json: {
      status: 200,
      msg: 'ok',
      data: {
        total: total,
        page: page,
        per_page: per_page,
        checkins: data
      }
    }
  end

  # POST /api/mobile/admin/users/:id/update_balance
  def update_balance
    user = User.where(type: nil).find_by(id: params[:id])
    return render json: { status: 404, msg: '用户不存在' }, status: :not_found unless user

    if params.key?(:balance)
      user.update!(balance: params[:balance].to_i)
    elsif params.key?(:amount)
      user.update!(balance: (user.balance || 0) + params[:amount].to_i)
    else
      return render json: { status: 400, msg: '缺少参数: balance 或 amount' }, status: :bad_request
    end

    render json: {
      status: 200,
      msg: '修改成功',
      data: { balance: user.balance }
    }
  end

  # GET /api/mobile/admin/config
  def get_config
    config = InstallationConfig.find_by(name: 'MOBILE_CHECKIN_AMOUNT')
    amount = config&.serialized_value || 5

    render json: {
      status: 200,
      msg: 'ok',
      data: {
        checkin_amount: amount.to_i
      }
    }
  end

  # POST /api/mobile/admin/config
  def update_config
    if params[:checkin_amount].present?
      config = InstallationConfig.find_or_initialize_by(name: 'MOBILE_CHECKIN_AMOUNT')
      config.serialized_value = params[:checkin_amount].to_i
      config.save!

      render json: {
        status: 200,
        msg: '配置更新成功',
        data: {
          checkin_amount: config.serialized_value
        }
      }
    else
      render json: { status: 400, msg: '缺少参数: checkin_amount' }, status: :bad_request
    end
  end

  private

  def authenticate_admin!
    auth_header = request.headers['Authorization']
    unless auth_header&.start_with?('Bearer ')
      return render json: { status: 401, msg: '未授权' }, status: :unauthorized
    end

    token = auth_header.sub('Bearer ', '').strip
    access_token = AccessToken.find_by(token: token)
    
    # 验证是否是 SuperAdmin 的 Token
    unless access_token && access_token.owner.is_a?(User) && access_token.owner.type == 'SuperAdmin'
      return render json: { status: 403, msg: '权限不足' }, status: :forbidden
    end

    @current_admin = access_token.owner
  end
end
