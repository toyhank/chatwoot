class ContactPushNotificationListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    
    # 异步发送推送，避免阻塞消息创建
    Notification::ContactPushNotificationJob.perform_later(message.id)
  end
end
