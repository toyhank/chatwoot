#!/usr/bin/env ruby
# 创建测试账号脚本

email = 'demo@test.com'
password = 'Demo@12345'

user = User.find_by(email: email)

if user.nil?
  user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    name: 'Demo User',
    confirmed_at: Time.current
  )
  puts '✅ 新建测试账号'
else
  puts '✅ 使用已存在的账号'
end

puts ''
puts '==================== 测试账号信息 ===================='
puts "邮箱 (Email):      #{user.email}"
puts "密码 (Password):   #{password}"
puts "用户ID (UID):      #{user.id}"
puts "昵称 (Nickname):   #{user.name}"
puts "Access Token:      #{user.access_token.token}"
puts '===================================================='
