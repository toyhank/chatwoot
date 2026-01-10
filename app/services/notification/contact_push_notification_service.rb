class Notification::ContactPushNotificationService
  pattr_initialize [:message!]

  def perform
    return unless should_send_push?

    contact_push_subscriptions.each do |subscription|
      send_fcm_push(subscription)
    end
  end

  private

  def should_send_push?
    # 只有客服发出的 outgoing 消息才发送推送
    # 不发送私有消息
    # 不发送自动回复
    message.outgoing? && 
      !message.private? && 
      message.sender.is_a?(User) &&
      !message.content_attributes.dig('automation_rule_id')
  end

  def contact_push_subscriptions
    return [] unless conversation.contact

    ContactPushSubscription.where(
      contact_id: conversation.contact.id,
      contact_inbox_id: conversation.contact_inbox_id
    )
  end

  def conversation
    @conversation ||= message.conversation
  end

  def send_fcm_push(subscription)
    return unless firebase_credentials_present?

    fcm_service = Notification::FcmService.new(
      GlobalConfigService.load('FIREBASE_PROJECT_ID', nil),
      GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
    )
    fcm = fcm_service.fcm_client
    response = fcm.send_v1(fcm_options(subscription))
    
    Rails.logger.info("Contact push sent to #{subscription.push_token[0..20]}... for message #{message.id}")
    
    remove_subscription_if_error(subscription, response)
  rescue StandardError => e
    Rails.logger.error("Contact push error: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  def firebase_credentials_present?
    GlobalConfigService.load('FIREBASE_PROJECT_ID', nil) && 
      GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)
  end

  def remove_subscription_if_error(subscription, response)
    response_body = JSON.parse(response[:body])
    if response_body.dig('error') || response_body.dig('results')&.first&.dig('error')
      Rails.logger.info("Removing invalid contact push subscription: #{subscription.id}")
      subscription.destroy!
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse FCM response: #{e.message}")
  end

  def fcm_options(subscription)
    {
      'token': subscription.push_token,
      'data': fcm_data,
      'notification': fcm_notification,
      'android': fcm_android_options,
      'apns': fcm_apns_options
    }
  end

  def fcm_data
    {
      payload: {
        data: {
          message_id: message.id,
          conversation_id: conversation.id,
          sender_name: message.sender.name,
          content: message.content
        }
      }.to_json
    }
  end

  def fcm_notification
    {
      title: notification_title,
      body: notification_body
    }
  end

  def notification_title
    sender_name = message.sender&.name || conversation.inbox.name
    "#{sender_name} 回复了您"
  end

  def notification_body
    return message.content if message.content.present?
    
    # 如果没有文本内容，显示附件信息
    return '[图片]' if message.attachments.any?(&:image?)
    return '[文件]' if message.attachments.any?
    
    '[新消息]'
  end

  def fcm_android_options
    {
      priority: 'high'
    }
  end

  def fcm_apns_options
    {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  end
end
