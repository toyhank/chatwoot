u = User.where(type: 'SuperAdmin').first
if u
  puts "Email: #{u.email}"
  u.password = 'Password123!'
  u.password_confirmation = 'Password123!'
  u.save!(validate: false)
  puts "Password reset to: Password123!"
else
  puts "No SUPER ADMIN!"
end
