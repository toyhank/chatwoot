# 账号注销 API 文档 (前端对接)

## 接口概述

**用途**: 永久删除用户账户及所有相关数据  
**版本**: v1.0  
**状态**: ✅ 已实现并测试通过

---

## 接口信息

| 项目             | 值                        |
| ---------------- | ------------------------- |
| **请求路径**     | `/api/mobile/user/delete` |
| **请求方法**     | `DELETE`                  |
| **认证方式**     | Bearer Token (必需)       |
| **Content-Type** | `application/json`        |

---

## 认证说明

请求头必须包含 Bearer Token：

```
Authorization: Bearer <user_access_token>
```

### 如何获取 Bearer Token

**Token 来源**: 用户登录成功后，从登录接口的响应中获取

**登录接口**: `POST /api/mobile/register/login`

**登录响应示例**:

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
    "access_token": "whuv127dcp1DR1ToLMhrjJT7", // ⭐ 这就是需要的 Bearer Token
    "message": "登录成功"
  }
}
```

**存储建议**:

- 登录成功后，将 `access_token` 保存到本地存储（localStorage/SharedPreferences）
- 在调用删除账号等需要认证的接口时使用这个 token
- 登出或删除账号后，清除本地存储的 token

**示例代码**:

```javascript
// 登录时保存 token
async function login(email, password) {
  const response = await fetch('/api/mobile/register/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const data = await response.json();

  if (response.ok) {
    // 保存 token 到本地存储
    localStorage.setItem('access_token', data.data.access_token);
    localStorage.setItem('user_id', data.data.uid);
    return data.data;
  }
}

// 删除账号时使用 token
async function deleteAccount() {
  const token = localStorage.getItem('access_token');
  return await fetch('/api/mobile/user/delete', {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
}
```

> **重要提示**:
>
> - Token 在用户登录时自动生成，每个用户有唯一的 token
> - Token 无过期时间，除非用户被删除或修改密码
> - Token 删除后立即失效，任何使用该 Token 的请求都会返回 401

> **重要**:
>
> - Token 从后端数据库的 `access_tokens` 表获取，不是登录接口返回的其他字段
> - 每个用户有一个唯一的 access_token，在用户创建时自动生成
> - Token 验证失败将返回 401 错误

---

## 请求示例

### cURL 示例

```bash
curl -X DELETE https://your-domain.com/api/mobile/user/delete \
  -H "Authorization: Bearer g57c88eKk5aTN3sS2MrRuHuP" \
  -H "Content-Type: application/json"
```

### JavaScript (fetch) 示例

```javascript
async function deleteAccount(bearerToken) {
  try {
    const response = await fetch(
      'https://your-domain.com/api/mobile/user/delete',
      {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const data = await response.json();

    if (response.ok) {
      console.log('账户删除成功:', data);
      // 清理本地数据，跳转到登录页
    } else {
      console.error('删除失败:', data);
    }

    return data;
  } catch (error) {
    console.error('请求错误:', error);
    throw error;
  }
}
```

### Dart (Flutter) 示例

```dart
Future<Map<String, dynamic>> deleteAccount(String bearerToken) async {
  final response = await http.delete(
    Uri.parse('https://your-domain.com/api/mobile/user/delete'),
    headers: {
      'Authorization': 'Bearer $bearerToken',
      'Content-Type': 'application/json',
    },
  );

  final data = json.decode(response.body);

  if (response.statusCode == 200) {
    print('账户删除成功');
    // 清理本地数据，跳转到登录页
  } else {
    print('删除失败: ${data['msg']}');
  }

  return data;
}
```

---

## 响应说明

### 成功响应 (200 OK)

**HTTP 状态码**: `200`

```json
{
  "status": 200,
  "msg": "账户删除成功",
  "data": null
}
```

**字段说明**:

- `status`: 业务状态码，200 表示成功
- `msg`: 成功提示信息
- `data`: 数据字段，删除操作返回 null

---

### 错误响应

#### 1. 未授权 (401 Unauthorized)

**场景**: Token 无效、已过期或缺失

**HTTP 状态码**: `401`

```json
{
  "status": 401,
  "msg": "未授权,请先登录"
}
```

**可能原因**:

- Authorization header 缺失
- Bearer Token 格式错误
- Token 无效或已被删除
- Token 对应的用户已被删除

#### 2. 服务器错误 (500 Internal Server Error)

**场景**: 服务器内部错误

**HTTP 状态码**: `500`

```json
{
  "status": 500,
  "msg": "服务器错误,请稍后重试"
}
```

---

## 前端实现流程

### 推荐实现步骤

```
1. 用户点击"删除账号"按钮
   ↓
2. 显示第一次确认对话框
   "确定要删除账号吗？此操作不可恢复！"
   ↓
3. 用户确认后，显示第二次确认对话框
   "再次确认：您的所有数据将被永久删除"
   ↓
4. 调用删除 API (DELETE /api/mobile/user/delete)
   ↓
5. 根据响应处理：
   - 成功 (200): 清理本地数据 → 跳转登录页 → 显示成功提示
   - 失败 (401): 提示"登录已过期，请重新登录"
   - 失败 (500): 提示"服务器错误，请稍后重试"
```

### 删除成功后的前端操作

```javascript
// 1. 清理本地存储
localStorage.clear();
sessionStorage.clear();
// 或针对性清理
localStorage.removeItem('userToken');
localStorage.removeItem('userId');
localStorage.removeItem('userEmail');

// 2. 重置应用状态
// 根据你的状态管理方案 (Redux/Vuex/Provider 等)
dispatch({ type: 'LOGOUT' });

// 3. 跳转到登录页
window.location.href = '/login';
// 或使用路由
router.push('/login');
```

---

## 注意事项

### ⚠️ 重要提醒

1. **不可逆操作**: 账号删除后无法恢复，前端必须有明确的二次确认机制
2. **数据清理**: 删除成功后，前端必须清理所有本地缓存数据
3. **Token 失效**: 删除后 Token 立即失效，任何使用该 Token 的请求都会返回 401
4. **网络错误**: 建议添加网络超时和错误重试机制
5. **用户体验**: 建议显示加载状态，避免用户重复点击

### 🔒 安全建议

1. **二次确认**: 必须实现至少两次用户确认
2. **敏感操作标识**: 删除按钮使用红色等警示颜色
3. **操作提示**: 明确告知用户删除的后果（数据永久丢失）
4. **防误触**: 避免在容易误触的位置放置删除按钮

### 📝 测试建议

在集成前请测试以下场景：

- [ ] 正常删除流程（有效 Token）
- [ ] 无效 Token 错误提示
- [ ] 网络错误处理
- [ ] 删除后无法再次登录
- [ ] 本地数据清理完整性
- [ ] UI 反馈和加载状态

---

## 变更说明

### 与原始规范的差异

原始规范文档 (API_DELETE_ACCOUNT.md) 定义的响应格式为：

```json
{
  "code": 200,
  "message": "账户删除成功",
  "data": null
}
```

**实际实现的响应格式**（与其他移动端 API 保持一致）：

```json
{
  "status": 200,
  "msg": "账户删除成功",
  "data": null
}
```

**差异对比**:
| 原规范 | 实际实现 | 说明 |
|--------|---------|------|
| `code` | `status` | 字段名不同，含义相同 |
| `message` | `msg` | 字段名不同，含义相同 |
| `data` | `data` | 一致 |

> **原因**: 为了与现有 `/api/mobile/register/*` 接口保持一致性，采用了统一的响应格式。

---

## 快速测试

### 测试环境

```bash
# 使用无效 token 测试（不会删除真实数据）
curl -X DELETE https://your-domain.com/api/mobile/user/delete \
  -H "Authorization: Bearer test_invalid_token" \
  -H "Content-Type: application/json"

# 预期响应:
# {"status":401,"msg":"未授权,请先登录"}
```

---

## 联系方式

如有问题或需要技术支持，请联系后端开发团队。

**文档版本**: v1.0  
**更新日期**: 2026-02-03  
**测试状态**: ✅ 已在开发和测试环境验证通过
