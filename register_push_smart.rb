# register_push_smart.rb
# Usage: docker-compose exec rails bundle exec rails runner register_push_smart.rb <email> <token>

email = ARGV[0]
token = ARGV[1]

if email.blank? || token.blank?
  puts "Usage: rails runner register_push_smart.rb <email> <token>"
  exit 1
end

puts "---------------------------------------------------"
puts "🚀 Smart Push Registration"
puts "---------------------------------------------------"
puts "📧 Email: #{email}"
puts "🔑 Token: #{token[0..20]}..."

# 1. Find the Contact (Global lookup by email OR Latest Active Contact)
# Smart Mode: Prioritize the contact involved in the latest message (regardless of sender)
active_contact = nil
last_msg = Message.order(created_at: :desc).first
if last_msg
  active_contact = last_msg.conversation.contact
  puts "🔎 Detected Active Contact from conversation ##{last_msg.conversation.id}: ID #{active_contact.id}"
end

contacts = Contact.where(email: email).to_a
if active_contact && !contacts.include?(active_contact)
  puts "⚠️ Active contact (ID #{active_contact.id}) has different/no email. Adding to list."
  contacts << active_contact
end

if contacts.empty?
  puts "❌ Contact not found with email: #{email} and no active history."
  exit 1
end

contacts.each do |contact|
  puts "\n----------------------------------------"
  puts "👤 Contact ID: #{contact.id} (Account: #{contact.account_id})"
  
  # 2. Find all Contact Inboxes associated with this contact
  contact_inboxes = ContactInbox.where(contact_id: contact.id)
  
  if contact_inboxes.empty?
    puts "  ⚠️ No Contact Inboxes found (User hasn't started any conversations)."
    next
  end

  puts "  found #{contact_inboxes.count} associated inboxes."

  puts "  found #{contact_inboxes.count} associated inboxes."

  # 3. Find the "Best" Inbox (One with most recent conversation)
  # We can't register for ALL because push_token must be unique globally.
  best_contact_inbox = nil
  latest_message_time = Time.at(0)

  contact_inboxes.each do |ci|
    last_msg = ci.conversations.order(updated_at: :desc).first
    if last_msg && last_msg.updated_at > latest_message_time
      best_contact_inbox = ci
      latest_message_time = last_msg.updated_at
    end
  end

  # Fallback: exact inbox ID 1 ID 30 if known, or just the first one
  best_contact_inbox ||= contact_inboxes.first

  puts "  🎯 Target Inbox: ##{best_contact_inbox.inbox.id} (ContactInbox: #{best_contact_inbox.id})"

  # 4. Handle Unique Constraint (Move token if needed)
  existing = ContactPushSubscription.find_by(push_token: token)
  
  if existing
    if existing.contact_inbox_id == best_contact_inbox.id
        puts "    ✅ Already correctly registered (ID: #{existing.id})"
        next
    else
        puts "    ⚠️ Token taken by ContactInbox #{existing.contact_inbox_id}. Moving it..."
        existing.destroy!
    end
  end

  # 5. Create new subscription
  sub = ContactPushSubscription.create!(
    contact_id: contact.id,
    contact_inbox_id: best_contact_inbox.id,
    push_token: token,
    device_id: "smart_script_#{Time.now.to_i}",
    platform: 'android'
  )
  puts "    🎉 Registered! (ID: #{sub.id})"
end

puts "\n---------------------------------------------------"
puts "✅ Smart Registration Complete"
