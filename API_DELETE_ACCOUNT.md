# Account Deletion API Documentation

## 账户删除接口文档

该文档为后端开发团队提供账户删除功能的API规范。此接口用于永久删除用户账户及其相关数据，以符合Apple App Store审核指南5.1.1(v)的要求。

---

## 接口信息

### 基本信息
- **接口路径**: `/api/mobile/user/delete`
- **请求方法**: `DELETE`
- **需要认证**: 是（需要Bearer Token）
- **内容类型**: `application/json`

### 认证方式
请求头需要包含用户的身份认证令牌：
```
Authorization: Bearer <user_token>
```

---

## 请求说明

### 请求参数
该接口不需要请求体参数。用户身份通过Authorization header中的Bearer Token识别。

### 请求示例
```http
DELETE /api/mobile/user/delete HTTP/1.1
Host: your-api-server.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

---

## 响应说明

### 成功响应
**HTTP状态码**: `200 OK`

**响应体结构**:
```json
{
  "code": 200,
  "message": "账户删除成功",
  "data": null
}
```

**字段说明**:
- `code` (number): 业务状态码，200表示成功
- `message` (string): 成功信息
- `data` (null): 数据字段，删除操作返回null

### 错误响应

#### 1. 未授权 (401 Unauthorized)
Token无效或已过期：
```json
{
  "code": 401,
  "message": "未授权，请先登录",
  "data": null
}
```

#### 2. 用户不存在 (404 Not Found)
Token有效但用户已不存在：
```json
{
  "code": 404,
  "message": "用户不存在",
  "data": null
}
```

#### 3. 服务器错误 (500 Internal Server Error)
服务器内部错误：
```json
{
  "code": 500,
  "message": "服务器错误，请稍后重试",
  "data": null
}
```

---

## 后端实现要求

### 1. 身份验证
- ✅ 验证Authorization header中的Bearer Token
- ✅ 确认Token有效且未过期
- ✅ 提取Token中的用户ID

### 2. 数据删除范围
删除以下所有与用户相关的数据：

#### 核心用户数据
- ✅ 用户账户信息（users表）
- ✅ 用户个人资料
- ✅ 用户认证凭证（密码哈希等）

#### 业务相关数据
- ✅ 用户的所有消息记录
- ✅ 用户的会话数据
- ✅ 用户设置和偏好
- ✅ 用户上传的文件和附件

#### 关联数据
- ✅ 推送通知订阅
- ✅ 设备令牌（如FCM tokens）
- ✅ 会话令牌和刷新令牌
- ✅ 邀请记录（如果有）
- ✅ 统计数据

### 3. 删除策略建议

#### 方式一：硬删除（推荐用于GDPR合规）
直接从数据库中物理删除所有用户数据。

```sql
-- 示例SQL（需根据实际数据库结构调整）
BEGIN TRANSACTION;

DELETE FROM push_subscriptions WHERE user_id = ?;
DELETE FROM messages WHERE user_id = ?;
DELETE FROM sessions WHERE user_id = ?;
DELETE FROM user_settings WHERE user_id = ?;
DELETE FROM users WHERE id = ?;

COMMIT;
```

#### 方式二：软删除 + 定期清理
标记账户为已删除，保留一段时间后再物理删除。

```sql
-- 软删除
UPDATE users 
SET deleted_at = NOW(), 
    email = CONCAT('deleted_', id, '@deleted.com'),
    is_active = false
WHERE id = ?;

-- 定期清理任务（例如30天后）
DELETE FROM users WHERE deleted_at < NOW() - INTERVAL 30 DAY;
```

### 4. 安全考虑
- ✅ **防止误删**: 确保只删除Token对应的用户，不能删除其他用户
- ✅ **事务处理**: 使用数据库事务确保数据一致性
- ✅ **级联删除**: 正确配置外键级联删除或手动处理关联表
- ✅ **日志记录**: 记录删除操作日志（用户ID、删除时间、IP地址）用于审计
- ✅ **备份**: 在永久删除前考虑创建数据备份

### 5. 响应时间
- 建议在30秒内完成删除操作
- 如果数据量大，考虑异步处理：
  - 立即标记账户为"删除中"
  - 返回成功响应
  - 后台异步完成实际删除

---

## 测试建议

### 测试用例

1. **正常删除**
   - 使用有效Token请求删除
   - 验证返回200状态码
   - 验证数据库中数据已删除
   - 验证后续使用该Token无法访问

2. **无效Token**
   - 使用无效/过期Token
   - 验证返回401状态码

3. **重复删除**
   - 删除后再次使用相同Token请求
   - 验证返回401或404状态码

4. **数据完整性**
   - 删除账户A
   - 验证账户B的数据未受影响

---

## 前端调用代码（已实现）

前端已实现调用代码，位于：
- `lib/services/api_service.dart` - `deleteAccount()` 方法
- `lib/pages/user/user_page.dart` - UI和业务逻辑

前端会在以下情况下调用此API：
1. 用户在设置页面点击"Delete Account"
2. 确认两次删除警告对话框
3. 发送DELETE请求到 `/api/mobile/user/delete`
4. 成功后清理本地数据并跳转到登录页面

---

## 注意事项

1. **GDPR合规**: 确保完全删除用户数据，不保留任何个人信息
2. **审计日志**: 保留删除操作的审计日志（但不包含用户个人数据）
3. **关联清理**: 确保清理所有关联服务（如第三方推送服务）
4. **错误处理**: 即使部分删除失败，也要尽可能多地删除数据
5. **用户通知**: 可选择发送删除确认邮件到用户注册邮箱

---

## 实现检查清单

- [ ] 实现DELETE `/api/mobile/user/delete`接口
- [ ] 验证Bearer Token认证
- [ ] 实现数据库事务处理
- [ ] 删除所有用户相关数据（见"数据删除范围"）
- [ ] 返回标准JSON响应格式
- [ ] 添加错误处理和日志记录
- [ ] 编写单元测试
- [ ] 编写集成测试
- [ ] 更新API文档
- [ ] 部署到测试环境供前端测试

---

生成日期: 2026-02-03
