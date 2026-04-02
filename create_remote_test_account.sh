#!/bin/bash

echo "================================================"
echo "  创建远程服务器测试账号"
echo "  服务器: 43.157.0.135"
echo "================================================"
echo ""

ssh root@43.157.0.135 << 'ENDSSH'
cd /root/chatwoot
docker-compose exec -T rails bin/rails runner '
email = "test@example.com"
password = "Test@123456"

user = User.find_by(email: email)

if user.nil?
  user = User.create!(
    email: email,
    password: password,
    password_confirmation: password,
    name: "Demo User",
    confirmed_at: Time.current
  )
  puts "✅ 新建测试账号"
else
  puts "✅ 账号已存在"
end

puts ""
puts "==================== 测试账号信息 ===================="
puts "服务器: 43.157.0.135"
puts "邮箱: #{user.email}"
puts "密码: #{password}"
puts "UID: #{user.id}"
puts "昵称: #{user.name}"
puts "Token: #{user.access_token.token}"
puts "===================================================="
'
ENDSSH

echo ""
echo "✅ 完成！"
