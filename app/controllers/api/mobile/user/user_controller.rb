class Api::Mobile::User::UserController < Api::BaseController
  skip_before_action :authenticate_user!, :set_current_user, :handle_with_exception,
                     raise: false

  # DELETE /api/mobile/user/delete
  def delete
    # Extract Bearer token from Authorization header
    auth_header = request.headers['Authorization']
    
    unless auth_header&.start_with?('Bearer ')
      return render_error(status: 401, msg: '未授权,请先登录')
    end

    token = auth_header.sub('Bearer ', '').strip
    
    # Find user by access token
    access_token = AccessToken.find_by(token: token)
    unless access_token&.owner.is_a?(User)
      return render_error(status: 401, msg: '未授权,请先登录')
    end

    user = access_token.owner

    # Create audit log before deletion
    Rails.logger.info("User deletion initiated: user_id=#{user.id}, email=#{user.email}, ip=#{request.remote_ip}")

    begin
      ActiveRecord::Base.transaction do
        # User model has proper associations with dependent: :destroy_async
        # which will handle cascading deletion automatically
        user.destroy!
        
        Rails.logger.info("User deletion completed: user_id=#{user.id}")
        
        render_success(
          data: nil,
          msg: '账户删除成功'
        )
      end
    rescue ActiveRecord::RecordNotFound
      render_error(status: 404, msg: '用户不存在')
    rescue StandardError => e
      Rails.logger.error("User deletion failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render_error(status: 500, msg: '服务器错误,请稍后重试')
    end
  end

  # POST /api/mobile/user/check_in
  def check_in
    auth_header = request.headers['Authorization']
    
    unless auth_header&.start_with?('Bearer ')
      return render_error(status: 401, msg: '未授权,请先登录')
    end

    token = auth_header.sub('Bearer ', '').strip
    access_token = AccessToken.find_by(token: token)
    unless access_token&.owner.is_a?(User)
      return render_error(status: 401, msg: '未授权,请先登录')
    end

    user = access_token.owner

    if user.check_in!
      render_success(
        data: { balance: user.balance },
        msg: '签到成功，余额已增加'
      )
    else
      render json: {
        status: 422,
        msg: '今天已经签到过了',
        data: { balance: user.balance || 0 }
      }, status: :unprocessable_entity
    end
  end
  # GET /api/mobile/user/profile
  def profile
    auth_header = request.headers["Authorization"]
    unless auth_header&.start_with?("Bearer ")
      return render_error(status: 401, msg: "未授权,请先登录")
    end

    token = auth_header.sub("Bearer ", "").strip
    access_token = AccessToken.find_by(token: token)
    unless access_token&.owner.is_a?(User)
      return render_error(status: 401, msg: "未授权,请先登录")
    end

    user = access_token.owner
    render_success(
      data: {
        uid: user.id,
        email: user.email,
        name: user.name,
        balance: user.balance || 0
      }
    )
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
