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

    # 支持账号切换：如果push_token已被其他contact使用，先删除旧订阅
    # 这允许同一设备在切换账号时自动转移推送订阅
    if subscription.new_record? || subscription.push_token_changed?
      ContactPushSubscription.where(push_token: push_subscription_params[:push_token])
                             .where.not(id: subscription.id)
                             .destroy_all
    end

    # [PATCH] Smart Inbox Detection
    # If the user (identified by email) has a more active conversation in a different inbox,
    # register the subscription there instead.
    best_inbox = find_best_contact_inbox
    if best_inbox && best_inbox.id != @contact_inbox.id
      puts "SmartPush: Redirecting from Inbox #{@contact_inbox.id} to #{best_inbox.id}"
      subscription.contact_inbox = best_inbox
      
      # Re-run uniqueness cleanup for the NEW target inbox
      ContactPushSubscription.where(push_token: push_subscription_params[:push_token])
                             .where.not(id: subscription.id)
                             .destroy_all
    end

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

  def find_best_contact_inbox
    # 1. Get identifiers from current contact
    email = @contact&.email
    identifier = @contact&.identifier
    phone_number = @contact&.phone_number

    return nil if email.blank? && identifier.blank? && phone_number.blank?
    
    # 2. Find all related contacts in the same account
    # We match on Email OR Identifier OR Phone Number
    related_contacts = Contact.where(account_id: @contact.account_id)
                              .where(
                                "email = :email OR identifier = :email OR identifier = :identifier", 
                                email: email, 
                                identifier: identifier
                              )
    
    return nil if related_contacts.empty?

    best_ci = nil
    latest_time = Time.at(0)

    # Search all inboxes of these contacts for the most recent conversation
    related_contacts.each do |contact|
      contact.contact_inboxes.each do |ci|
        last_msg = ci.conversations.order(updated_at: :desc).first
        if last_msg && last_msg.updated_at > latest_time
          latest_time = last_msg.updated_at
          best_ci = ci
        end
      end
    end

    best_ci
  end

  def push_subscription_params
    params.require(:push_subscription).permit(:push_token, :device_id, :platform)
  end
end



