# 账号注销接口测试指南

## 方法一：使用 Docker 启动服务

### 1. 启动 Chatwoot 服务

```bash
cd /home/chatwoot1/chatwoot

# 使用 docker-compose 启动
docker-compose -f docker-compose.local.yml up -d

# 查看服务状态
docker-compose -f docker-compose.local.yml ps

# 查看日志
docker-compose -f docker-compose.local.yml logs -f rails
```

### 2. 等待服务启动

等待 Rails 服务完全启动（通常需要 30-60 秒），检查日志中是否出现：

```
* Listening on http://0.0.0.0:3000
```

## 方法二：直接使用已运行的服务

如果服务已在运行，直接使用测试脚本。

## 测试脚本使用

### 脚本 1: test_delete_simple.sh（推荐）

**适用场景**: 已有测试用户

```bash
cd /home/chatwoot1/chatwoot

# 使用默认用户 test@example.com
./test_delete_simple.sh

# 或指定用户
./test_delete_simple.sh your@email.com your_password http://localhost:3000
```

**执行流程**:

1. 脚本会提示你获取 Bearer Token
2. 在另一个终端执行命令获取 token
3. 将 token 输入到脚本中
4. 自动测试删除、无效token、缺失header等场景

### 脚本 2: test_delete_account.sh（完整流程）

**适用场景**: 从注册新用户开始完整测试

```bash
cd /home/chatwoot1/chatwoot

# 使用默认 URL
./test_delete_account.sh

# 或指定 URL
./test_delete_account.sh http://localhost:3000
```

**执行流程**:

1. 创建新的测试用户（需要邮箱验证码）
2. 获取 Bearer Token
3. 测试删除接口
4. 验证删除效果

## 手动 curl 测试示例

### 1. 获取 Bearer Token

首先从数据库获取现有用户的 token：

```bash
cd /home/chatwoot1/chatwoot
bin/rails runner "user = User.find_by(email: 'test@example.com'); puts user ? user.access_token.token : 'User not found'"
```

### 2. 测试删除账户（成功场景）

```bash
curl -X DELETE http://localhost:3000/api/mobile/user/delete \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
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

### 3. 测试无效 Token（401 错误）

```bash
curl -X DELETE http://localhost:3000/api/mobile/user/delete \
  -H "Authorization: Bearer invalid_token_12345" \
  -H "Content-Type: application/json"
```

**预期响应**:

```json
{
  "status": 401,
  "msg": "未授权,请先登录"
}
```

### 4. 测试缺失 Authorization Header（401 错误）

```bash
curl -X DELETE http://localhost:3000/api/mobile/user/delete \
  -H "Content-Type: application/json"
```

**预期响应**:

```json
{
  "status": 401,
  "msg": "未授权,请先登录"
}
```

### 5. 验证删除效果（尝试登录）

```bash
curl -X POST http://localhost:3000/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'
```

**预期响应** (如果用户已删除):

```json
{
  "status": 400,
  "msg": "邮箱或密码错误"
}
```

## 快速创建测试用户

如果需要快速创建测试用户：

```bash
cd /home/chatwoot1/chatwoot
bin/rails runner "
  user = User.create!(
    email: 'test@example.com',
    password: '123456',
    password_confirmation: '123456',
    name: 'Test User',
    confirmed_at: Time.current
  )
  puts \"User created with ID: #{user.id}\"
  puts \"Access Token: #{user.access_token.token}\"
"
```

## 故障排查

### Docker 服务未启动

```bash
# 检查 Docker 状态
docker ps

# 如果没有 Docker，可能需要启动 Docker Desktop（Windows）
# 或者使用系统原生 Ruby 环境
```

### Ruby 版本不匹配

如果遇到 Ruby 版本问题，需要：

1. 使用 Docker 启动（推荐）
2. 或使用 rbenv/rvm 切换到正确的 Ruby 版本

### 获取 Token 失败

```bash
# 确认用户存在
bin/rails runner "puts User.find_by(email: 'test@example.com').inspect"

# 确认 AccessToken 存在
bin/rails runner "user = User.find_by(email: 'test@example.com'); puts user.access_token.inspect"
```

## 测试清单

- [ ] 有效 Bearer token 删除账户（返回 200）
- [ ] 无效 token 返回 401
- [ ] 缺失 Authorization header 返回 401
- [ ] 删除后无法登录（验证删除成功）
- [ ] 重复删除返回 401
- [ ] 检查服务器日志中的审计记录

## 注意事项

1. **测试账户**: 建议使用专门的测试账户，不要删除重要数据
2. **服务重启**: CORS 配置更改需要重启服务才能生效
3. **日志监控**: 删除操作会在日志中记录，可以通过 `docker-compose logs -f rails` 查看
4. **数据备份**: 生产环境测试前请确保有数据备份

## 审计日志示例

删除操作会在 Rails 日志中产生以下记录：

```
User deletion initiated: user_id=123, email=test@example.com, ip=127.0.0.1
User deletion completed: user_id=123
```
