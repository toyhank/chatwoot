# 测试账号信息

**创建时间**: 2026-02-03  
**环境**: Docker 开发环境  
**用途**: API 测试和前端对接

---

## 📋 账号信息

| 项目             | 值                         |
| ---------------- | -------------------------- |
| **邮箱**         | `demo@test.com`            |
| **密码**         | `Demo@12345`               |
| **用户ID**       | `10`                       |
| **昵称**         | `Demo User`                |
| **Access Token** | `JxAAzG3v9jcPydji1myY7BdR` |

---

## 🧪 快速测试命令

### 1. 邮箱密码登录

```bash
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo@12345"}'
```

**预期响应**:

```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 10,
    "email": "demo@test.com",
    "nickname": "Demo User",
    "access_token": "JxAAzG3v9jcPydji1myY7BdR",
    "message": "登录成功"
  }
}
```

---

### 2. Token 快速登录（自动登录）

```bash
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"access_token":"JxAAzG3v9jcPydji1myY7BdR"}'
```

**预期响应**:

```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 10,
    "email": "demo@test.com",
    "access_token": "JxAAzG3v9jcPydji1myY7BdR",
    ...
  }
}
```

---

### 3. 删除账号

```bash
curl -X DELETE http://localhost:8080/api/mobile/user/delete \
  -H "Authorization: Bearer JxAAzG3v9jcPydji1myY7BdR" \
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

> ⚠️ **警告**: 删除后该账号将无法恢复！如需继续测试，请重新创建账号。

---

## 🔄 重新创建测试账号

如果账号被删除，可以运行以下命令重新创建：

```bash
cd /home/chatwoot1/chatwoot
docker-compose -f docker-compose.local.yml exec rails bin/rails runner /app/create_test_account.rb
```

---

## 📱 前端集成测试示例

### JavaScript / React

```javascript
const API_BASE = 'http://localhost:8080';

// 登录
async function login() {
  const response = await fetch(`${API_BASE}/api/mobile/register/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'demo@test.com',
      password: 'Demo@12345',
    }),
  });

  const data = await response.json();

  if (response.ok) {
    // 保存 token
    localStorage.setItem('access_token', data.data.access_token);
    console.log('登录成功:', data.data);
  }
}

// 自动登录
async function autoLogin() {
  const token = localStorage.getItem('access_token');

  const response = await fetch(`${API_BASE}/api/mobile/register/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ access_token: token }),
  });

  return await response.json();
}

// 删除账号
async function deleteAccount() {
  const token = localStorage.getItem('access_token');

  const response = await fetch(`${API_BASE}/api/mobile/user/delete`, {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  const data = await response.json();

  if (response.ok) {
    // 清理本地数据
    localStorage.clear();
    console.log('账号已删除');
  }

  return data;
}
```

### Flutter / Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

const API_BASE = 'http://localhost:8080';

// 登录
Future<Map<String, dynamic>> login() async {
  final response = await http.post(
    Uri.parse('$API_BASE/api/mobile/register/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': 'demo@test.com',
      'password': 'Demo@12345',
    }),
  );

  final data = json.decode(response.body);

  if (response.statusCode == 200) {
    // 保存 token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['data']['access_token']);
  }

  return data;
}

// 删除账号
Future<Map<String, dynamic>> deleteAccount() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.delete(
    Uri.parse('$API_BASE/api/mobile/user/delete'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = json.decode(response.body);

  if (response.statusCode == 200) {
    // 清理本地数据
    await prefs.clear();
  }

  return data;
}
```

---

## 🔍 验证测试

完整的测试流程：

```bash
# 1. 登录获取 token
TOKEN=$(curl -s -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo@12345"}' \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

echo "获取到的 Token: $TOKEN"

# 2. 使用 token 自动登录
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d "{\"access_token\":\"$TOKEN\"}"

# 3. 删除账号
curl -X DELETE http://localhost:8080/api/mobile/user/delete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# 4. 验证删除（应该失败）
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo@12345"}'
```

---

## 📝 注意事项

1. **环境限制**: 此账号仅在 Docker 开发环境中有效（localhost:8080）
2. **数据持久性**: 如果重启 Docker 容器且未使用持久化卷，数据可能丢失
3. **安全提醒**: 这是测试账号，不要用于生产环境
4. **Token 永久性**: Access token 不会过期，除非删除用户

---

## 相关文档

- [API 删除账号文档（前端版）](API_DELETE_ACCOUNT_FRONTEND.md)
- [登录接口变更说明](LOGIN_API_CHANGELOG.md)
- [测试报告](TEST_REPORT_DELETE_ACCOUNT.md)
