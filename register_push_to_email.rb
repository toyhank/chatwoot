# usage: rails runner register_push_to_email.rb <email_or_identifier> <fcm_token>

identifier = ARGV[0]
fcm_token = ARGV[1]

if identifier.blank? || fcm_token.blank?
  puts "Usage: rails runner register_push_to_email.rb <email_or_identifier> <fcm_token>"
  exit 1
end

puts "Finding contact for: #{identifier}"

# Find contact
contact = Contact.find_by(email: identifier) || Contact.find_by(identifier: identifier)

unless contact
  puts "Error: Contact not found!"
  exit 1
end

puts "Found Contact ID: #{contact.id}, Name: #{contact.name}"

# Find ContractInbox (assuming Inbox 1 or checking for the correct one)
# We generally want the Website widget inbox.
# You might want to adjust logic if you have multiple inboxes.
contact_inbox = ContactInbox.where(contact_id: contact.id).order(created_at: :desc).first

unless contact_inbox
  puts "Error: ContactInbox not found for this contact!"
  exit 1
end

puts "Using ContactInbox ID: #{contact_inbox.id} (Inbox ID: #{contact_inbox.inbox_id})"

# Generate JWT Auth Token
payload = { source_id: contact_inbox.source_id, inbox_id: contact_inbox.inbox_id }
auth_token = Widget::TokenService.new(payload: payload).generate_token

puts "Generated JWT Auth Token."

# API Configuration
base_url = "http://localhost:3000"
website_token = "GJFzMx6qnv9DFpaspRpFDRDt" # Ensure this matches the inbox found or fetch it
# Ideally fetching website token from the inbox of the contact_inbox
inbox = contact_inbox.inbox
channel = inbox.channel
if channel.is_a?(Channel::WebWidget)
  website_token = channel.website_token
  puts "Using Website Token from Inbox: #{website_token}"
else
  puts "Warning: Inbox channel is not a WebWidget. Using default or hardcoded token might fail if mismatched."
end

uri = URI("#{base_url}/api/v1/widget/push_subscriptions")
http = Net::HTTP.new(uri.host, uri.port)
req = Net::HTTP::Post.new(uri)
req['Content-Type'] = 'application/json'
req['X-Auth-Token'] = auth_token
req.body = {
  website_token: website_token,
  push_subscription: {
    push_token: fcm_token,
    device_id: "script_#{Time.now.to_i}", # Generate a new device ID for this script usage
    platform: 'android'
  }
}.to_json

puts "Calling API..."
response = http.request(req)

puts "Response Code: #{response.code}"
puts "Response Body: #{response.body}"

if response.code.to_i >= 200 && response.code.to_i < 300
  puts "✅ Registration Successful!"
else
  puts "❌ Registration Failed."
end
