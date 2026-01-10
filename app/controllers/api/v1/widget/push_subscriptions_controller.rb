class Api::V1::Widget::PushSubscriptionsController < Api::V1::Widget::BaseController
  include WidgetHelper

  def create
    subscription = ContactPushSubscription.find_or_initialize_by(
      contact_inbox: @contact_inbox,
      device_id: push_subscription_params[:device_id]
    )

    subscription.assign_attributes(
      contact: @contact,
      push_token: push_subscription_params[:push_token],
      platform: push_subscription_params[:platform] || 'android'
    )

    if subscription.save
      render json: subscription, status: :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # 支持按 device_id 删除（推荐）：允许同一设备切换用户时删除旧订阅
    # 向后兼容：如果没有 device_id，则按 push_token 删除
    if push_subscription_params[:device_id].present?
      # 按 device_id 删除：删除同一设备的所有旧订阅
      # 这样即使切换了用户（auth token 变了），也能删除旧用户的订阅
      subscription = ContactPushSubscription.find_by(
        device_id: push_subscription_params[:device_id]
      )
    elsif params[:push_token].present?
      # 向后兼容：按 push_token 删除当前用户的订阅
      subscription = ContactPushSubscription.find_by(
        contact_inbox: @contact_inbox,
        push_token: params[:push_token]
      )
    end

    if subscription
      subscription.destroy
      head :ok
    else
      head :not_found
    end
  end

  # 按 device_id 删除订阅（支持用户切换场景）
  # 即使用户切换（auth token 变了），也能删除同一设备的旧订阅
  def destroy_by_device
    subscription = ContactPushSubscription.find_by(
      device_id: push_subscription_params[:device_id]
    )

    if subscription
      subscription.destroy
      head :ok
    else
      head :not_found
    end
  end

  private

  def push_subscription_params
    params.require(:push_subscription).permit(:push_token, :device_id, :platform)
  end
end



