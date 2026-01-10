class Notification::ContactPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    Notification::ContactPushNotificationService.new(message: message).perform
  end
end
