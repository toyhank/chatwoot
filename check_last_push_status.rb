# check_last_push_status.rb
# Usage: docker-compose exec rails bundle exec rails runner check_last_push_status.rb

puts "---------------------------------------------------"
puts "🔍 Checking Last Message Push Status"
puts "---------------------------------------------------"

last_message = Message.last

if last_message.nil?
  puts "❌ No messages found."
  exit
end

puts "Message ID: #{last_message.id}"
puts "Content: #{last_message.content}"
puts "Type: #{last_message.message_type} (0: Incoming, 1: Outgoing)"
puts "Private: #{last_message.private?}"
puts "Created At: #{last_message.created_at}"
puts "Sender Type: #{last_message.sender_type}"

# Logic from ContactPushNotificationService#should_send_push?
is_outgoing = last_message.outgoing?
is_not_private = !last_message.private?
is_user_sender = last_message.sender.is_a?(User)
is_not_automation = !last_message.content_attributes.dig('automation_rule_id')

should_send = is_outgoing && is_not_private && is_user_sender && is_not_automation

puts "\n📋 Eligibility Check:"
puts "  - Outgoing? #{is_outgoing ? '✅' : '❌'}"
puts "  - Not Private? #{is_not_private ? '✅' : '❌'}"
puts "  - User Sender? #{is_user_sender ? '✅' : '❌'} (#{last_message.sender_type})"
puts "  - Not Automation? #{is_not_automation ? '✅' : '❌'}"
puts "----------------------------------------"
puts "  => Should Send Push? #{should_send ? '✅ YES' : '❌ NO'}"

unless should_send
  puts "\n🚫 Message is not eligible for push."
  exit
end

conversation = last_message.conversation
contact = conversation.contact
contact_inbox = conversation.contact_inbox

if contact.nil?
  puts "❌ No contact associated with conversation."
  exit
end

puts "\n👤 Contact Info:"
puts "  - ID: #{contact.id}"
puts "  - Name: #{contact.name}"
puts "  - Email: #{contact.email}"

puts "\n📥 Inbox Info:"
puts "  - Conversation Inbox ID: #{contact_inbox.inbox_id}"
puts "  - Contact Inbox ID (Conversation): #{contact_inbox.id}"

subscriptions = ContactPushSubscription.where(
  contact_id: contact.id,
  contact_inbox_id: contact_inbox.id
)

puts "\n📱 Push Subscriptions (#{subscriptions.count}):"
if subscriptions.empty?
  puts "  ❌ No subscriptions found for this contact/inbox pair."
else
  subscriptions.each do |sub|
    puts "  - ID: #{sub.id} | Platform: #{sub.platform} | Token: #{sub.push_token[0..20]}..."
  end
end

puts "\n---------------------------------------------------"
puts "🚀 Attempting Dry-Run Send (Verifying Connectivity & Credentials)..."

project_id = GlobalConfigService.load('FIREBASE_PROJECT_ID', nil)
credentials = GlobalConfigService.load('FIREBASE_CREDENTIALS', nil)

if project_id.blank? || credentials.blank?
  puts "❌ Firebase credentials missing in GlobalConfigService."
  exit
end

subscriptions.each do |sub|
  puts "\nTesting Subscription ##{sub.id}..."
  
  fcm_service = Notification::FcmService.new(project_id, credentials)
  fcm = fcm_service.fcm_client
  
  # Construct payload same as service
  options = {
      'token': sub.push_token,
      'notification': {
        'title': "Debug Check: #{last_message.sender&.name}",
        'body': last_message.content.presence || "[Attachment]"
      },
      'android': { 'priority': 'high' }
  }
  
  begin
    response = fcm.send_v1(options)
    puts "  📡 FCM Response Status: #{response[:status_code]}"
    puts "  📄 Body: #{response[:body]}"
    
    body = JSON.parse(response[:body])
    if body['name']
       puts "  ✅ SUCCESS: Message accepted by FCM."
    else
       puts "  ❌ FAILURE: #{body}"
    end
  rescue => e
    puts "  ❌ Exception during send: #{e.message}"
  end
end

puts "\n---------------------------------------------------"
puts "🏁 Check Complete"
