# 🎯 生产服务器测试账号信息

**服务器**: 43.157.0.135  
**创建时间**: 2026-02-03  
**状态**: ✅ 已创建

---

## 📋 账号信息

| 项目                | 值                         |
| ------------------- | -------------------------- |
| **邮箱 (Email)**    | `demo@test.com`            |
| **密码 (Password)** | `Demo@12345`               |
| **用户ID (UID)**    | `6`                        |
| **昵称 (Nickname)** | `Demo User`                |
| **Access Token**    | `LPKknzVt9pxRtnXh1S9hNXvj` |
| **服务器地址**      | `43.157.0.135`             |

---

## 🧪 API 测试命令

### 1️⃣ 邮箱密码登录

```bash
curl -X POST http://43.157.0.135/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo@12345"}'
```

**预期响应**:

```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 6,
    "email": "demo@test.com",
    "nickname": "Demo User",
    "access_token": "LPKknzVt9pxRtnXh1S9hNXvj",
    ...
  }
}
```

---

### 2️⃣ Token 自动登录

```bash
curl -X POST http://43.157.0.135/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"access_token":"LPKknzVt9pxRtnXh1S9hNXvj"}'
```

---

### 3️⃣ 删除账号

```bash
curl -X DELETE http://43.157.0.135/api/mobile/user/delete \
  -H "Authorization: Bearer LPKknzVt9pxRtnXh1S9hNXvj" \
  -H "Content-Type: application/json"
```

**预期响应**:

```json
{
  "status": 200,
  "msg": "账户删除成功",
  "data": null
}
```

---

## 🔄 重新创建账号

如果测试账号被删除，可以重新运行脚本：

```bash
cd /home/chatwoot1/chatwoot
./create_remote_test_account.sh
```

或直接在服务器上执行：

```bash
ssh root@43.157.0.135
cd /root/chatwoot
docker-compose exec -T rails bin/rails runner '
email = "demo@test.com"
password = "Demo@12345"
user = User.find_by(email: email) || User.create!(
  email: email,
  password: password,
  password_confirmation: password,
  name: "Demo User",
  confirmed_at: Time.current
)
puts "Email: #{user.email}"
puts "Token: #{user.access_token.token}"
'
```

---

## 📱 前端测试配置

### JavaScript

```javascript
const API_BASE = 'http://43.157.0.135';
const TEST_EMAIL = 'demo@test.com';
const TEST_PASSWORD = 'Demo@12345';
const TEST_TOKEN = 'LPKknzVt9pxRtnXh1S9hNXvj';
```

### Flutter/Dart

```dart
const String apiBase = 'http://43.157.0.135';
const String testEmail = 'demo@test.com';
const String testPassword = 'Demo@12345';
const String testToken = 'LPKknzVt9pxRtnXh1S9hNXvj';
```

---

## ⚠️ 注意事项

1. **生产环境**: 这是生产服务器测试账号，请谨慎使用
2. **Token 有效期**: Access token 永久有效，直到用户被删除
3. **删除操作**: 删除账号是不可逆的，请确认后再执行
4. **安全提醒**: 测试完成后建议删除测试账号

---

## 相关文档

- [API 删除账号文档](API_DELETE_ACCOUNT_FRONTEND.md)
- [登录接口变更说明](LOGIN_API_CHANGELOG.md)
- [本地测试账号](TEST_ACCOUNT.md)
