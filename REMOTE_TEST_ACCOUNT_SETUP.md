# 生产服务器测试账号创建脚本

## 服务器信息

- **服务器IP**: 43.157.0.135
- **环境**: Docker

## 创建测试账号命令

在远程服务器上执行以下命令：

```bash
# SSH 连接到服务器
ssh root@43.157.0.135

# 进入 chatwoot 目录（根据实际路径调整）
cd /root/chatwoot

# 创建测试账号
docker-compose exec rails bin/rails runner "
email = 'test@example.com'
password = 'Test@123456'
user = User.find_by(email: email) || User.create!(
  email: email,
  password: password,
  password_confirmation: password,
  name: 'Demo User',
  confirmed_at: Time.current
)
puts '邮箱: ' + user.email
puts '密码: ' + password
puts 'UID: ' + user.id.to_s
puts 'Token: ' + user.access_token.token
"
```

## 测试 API 端点

```bash
# 1. 登录测试
curl -X POST http://43.157.0.135/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo@12345"}'

# 2. Token 登录测试
curl -X POST http://43.157.0.135/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"access_token":"YOUR_TOKEN_HERE"}'

# 3. 删除账号测试
curl -X DELETE http://43.157.0.135/api/mobile/user/delete \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

## 一键执行脚本

将以下内容保存为 `create_remote_test_account.sh`:

```bash
#!/bin/bash

echo "正在远程服务器 43.157.0.135 创建测试账号..."

ssh root@43.157.0.135 << 'ENDSSH'
cd /root/chatwoot
docker-compose exec -T rails bin/rails runner "
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
  puts '✅ 账号已存在'
end
puts ''
puts '==================== 测试账号信息 ===================='
puts '服务器: 43.157.0.135'
puts '邮箱: ' + user.email
puts '密码: ' + password
puts 'UID: ' + user.id.to_s
puts '昵称: ' + user.name
puts 'Token: ' + user.access_token.token
puts '===================================================='
"
ENDSSH

echo "完成！"
```

使用方法：

```bash
chmod +x create_remote_test_account.sh
./create_remote_test_account.sh
```
