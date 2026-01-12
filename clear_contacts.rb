# clear_contacts.rb
# Usage: docker-compose exec rails bundle exec rails runner clear_contacts.rb

puts "---------------------------------------------------"
puts "🗑️  Clearing All Contacts..."
puts "---------------------------------------------------"

initial_count = Contact.count
puts "Found #{initial_count} contacts."

if initial_count > 0
  # Contact.destroy_all triggers callbacks to delete dependent objects 
  # (Conversations, Messages, ContactInboxes, PushSubscriptions, etc.)
  Contact.find_each do |c|
    begin
      # Manually cleanup dependencies to avoid FK constraints if cascade is missing
      c.contact_push_subscriptions.destroy_all
      c.conversations.destroy_all
      c.contact_inboxes.destroy_all
      
      c.destroy!
      print "."
    rescue => e
      puts "\n❌ Failed to delete Contact #{c.id}: #{e.message}"
    end
  end
  puts "\n✅ Cleanup finished."
else
  puts "✨ No contacts to delete."
end

puts "---------------------------------------------------"
puts "🏁 Cleanup Complete"
