# 登录接口更新说明

## 变更内容

**接口**: `POST /api/mobile/register/login`

**变更日期**: 2026-02-03

## 更新详情

### 响应数据新增字段

登录成功后的响应中新增了 `access_token` 字段：

#### 变更前:

```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 9,
    "email": "test@example.com",
    "nickname": "Test User",
    "avatar": "http://...",
    "phone": "",
    "message": "登录成功"
  }
}
```

#### 变更后:

```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 9,
    "email": "test@example.com",
    "nickname": "Test User",
    "avatar": "http://...",
    "phone": "",
    "access_token": "whuv127dcp1DR1ToLMhrjJT7", // ⭐ 新增字段
    "message": "登录成功"
  }
}
```

### 变更原因

为了支持账号注销功能，前端需要使用 `access_token` 作为 Bearer Token 来调用删除账号接口 (`DELETE /api/mobile/user/delete`)。

### 前端适配建议

#### 1. 保存 access_token

登录成功后，将 `access_token` 保存到本地存储：

```javascript
// JavaScript
const loginData = response.data;
localStorage.setItem('access_token', loginData.access_token);
```

```dart
// Flutter/Dart
final loginData = response['data'];
await prefs.setString('access_token', loginData['access_token']);
```

#### 2. 使用 access_token

调用需要认证的接口时，使用保存的 token：

```javascript
// JavaScript
const token = localStorage.getItem('access_token');
fetch('/api/mobile/user/delete', {
  method: 'DELETE',
  headers: {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
});
```

```dart
// Flutter/Dart
final token = await prefs.getString('access_token');
await http.delete(
  Uri.parse('$baseUrl/api/mobile/user/delete'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

#### 3. 清理 token

登出或删除账号后，清除本地存储：

```javascript
// JavaScript
localStorage.removeItem('access_token');
localStorage.removeItem('user_id');
```

```dart
// Flutter/Dart
await prefs.remove('access_token');
await prefs.remove('user_id');
```

### 兼容性

- ✅ **向后兼容**: 该变更仅新增字段，不影响现有功能
- ✅ **可选使用**: 如果前端暂时不需要使用该 token，可以忽略此字段
- ⚠️ **必需使用**: 如果要实现账号删除功能，必须使用此 token

### 测试验证

已在测试环境验证通过：

```bash
# 测试登录并获取 token
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test@123"}'

# 响应包含 access_token
{
  "status": 200,
  "data": {
    "access_token": "whuv127dcp1DR1ToLMhrjJT7",
    ...
  }
}
```

### 相关文档

- [账号注销 API 文档](API_DELETE_ACCOUNT_FRONTEND.md)
- [测试报告](TEST_REPORT_DELETE_ACCOUNT.md)

---

如有问题请联系后端开发团队。
