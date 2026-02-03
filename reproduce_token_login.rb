require 'net/http'
require 'json'
require 'uri'

# Setup: ensure a user and token exist
begin
  # This part is meant to be run in rails console or via runner, but for external script we assume local server
  # We will try to get a valid token first if possible, or just use a placeholder if we can't easily fetch one.
  # Since this is an external script, we might need a way to get a token.
  # Let's try to register a user first to get a fresh ecosystem?
  # Actually, let's just assume we run this with `rails runner` so we can access models.
  
  if defined?(Rails)
    user = User.find_by(email: 'test_token_login@example.com')
    if user
      user.destroy
    end
    
    user = User.create!(
      email: 'test_token_login@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Token Tester',
      confirmed_at: Time.current
    )
    token = user.access_token.token
    puts "Created user with token: #{token}"
    
    # Now try to hit the API
    uri = URI("http://localhost:3000/api/mobile/register/login")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    
    # Payload with token
    request.body = { access_token: token }.to_json
    
    puts "Sending request to #{uri} with token..."
    response = http.request(request)
    
    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"
    
    if response.code == '200' && response.body.include?('test_token_login@example.com')
      puts "SUCCESS: Token login worked!"
    else
      puts "FAILURE: Token login failed."
    end
  else
    puts "Please run this script with `rails runner reproduce_token_login.rb`"
  end
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
