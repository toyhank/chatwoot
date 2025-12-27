# 邮箱注册登录接口测试指南

## 服务地址

- 基础URL: `http://localhost:8080`
- API前缀: `/api/mobile/register`

## 测试方法

### 方法 1: 使用提供的测试脚本（推荐）

```bash
# 运行测试脚本
./test_api.sh
```

### 方法 2: 使用 curl 命令行

#### 1. 检查邮箱是否可用

```bash
curl "http://localhost:8080/api/mobile/register/check_email?email=test@example.com"
```

**成功响应示例：**
```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "email": "test@example.com",
    "available": true,
    "message": "该邮箱可以使用"
  }
}
```

#### 2. 发送注册验证码

```bash
curl -X POST http://localhost:8080/api/mobile/register/send_code \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

**成功响应示例：**
```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "email": "test@example.com",
    "expire": 300,
    "message": "验证码已发送到您的邮箱，请注意查收"
  }
}
```

**注意**：验证码会发送到邮箱，也可以从数据库中查询：
```bash
# 查看验证码（在 Docker 容器中）
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails runner "
code = EmailVerificationCode.where(email: 'test@example.com').order(created_at: :desc).first
puts \"验证码: #{code.code}\" if code
"
```

#### 3. 用户注册

**注意**: Chatwoot 的密码要求至少包含：
- 1个大写字母 (A-Z)
- 1个小写字母 (a-z)  
- 1个数字 (0-9)
- 1个特殊字符 (!@#$%^&*()_+-=[]{}|"/\\.,`<>:;?~')

```bash
curl -X POST http://localhost:8080/api/mobile/register/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "806110",
    "password": "Test123!@#",
    "nickname": "测试用户"
  }'
```

**成功响应示例：**
```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 123,
    "email": "test@example.com",
    "nickname": "测试用户",
    "message": "注册成功"
  }
}
```

#### 4. 用户登录

```bash
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#"
  }'
```

**成功响应示例：**
```json
{
  "status": 200,
  "msg": "ok",
  "data": {
    "uid": 123,
    "email": "test@example.com",
    "nickname": "测试用户",
    "avatar": "/statics/default_avatar.png",
    "phone": "",
    "message": "登录成功"
  }
}
```

### 方法 3: 使用 Postman 或 HTTP 客户端

#### 导入 Postman Collection

创建以下请求：

1. **检查邮箱**
   - Method: `GET`
   - URL: `http://localhost:8080/api/mobile/register/check_email?email={email}`
   - Headers: 无

2. **发送验证码**
   - Method: `POST`
   - URL: `http://localhost:8080/api/mobile/register/send_code`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
     ```json
     {
       "email": "test@example.com"
     }
     ```

3. **用户注册**
   - Method: `POST`
   - URL: `http://localhost:8080/api/mobile/register/register`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
     ```json
     {
       "email": "test@example.com",
       "code": "123456",
       "password": "password123",
       "nickname": "测试用户"
     }
     ```

4. **用户登录**
   - Method: `POST`
   - URL: `http://localhost:8080/api/mobile/register/login`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
     ```json
     {
       "email": "test@example.com",
       "password": "password123"
     }
     ```

### 方法 4: 使用浏览器（仅限 GET 请求）

对于检查邮箱接口，可以直接在浏览器中访问：

```
http://localhost:8080/api/mobile/register/check_email?email=test@example.com
```

## 完整测试流程示例

```bash
# 1. 设置测试邮箱
EMAIL="test$(date +%s)@example.com"
echo "测试邮箱: $EMAIL"

# 2. 检查邮箱是否可用
echo "=== 1. 检查邮箱 ==="
curl "http://localhost:8080/api/mobile/register/check_email?email=$EMAIL" | jq

# 3. 发送验证码
echo ""
echo "=== 2. 发送验证码 ==="
curl -X POST http://localhost:8080/api/mobile/register/send_code \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\"}" | jq

# 4. 获取验证码（从数据库）
echo ""
echo "=== 获取验证码 ==="
CODE=$(docker-compose -f docker-compose.development.yaml exec -T rails bundle exec rails runner "
code = EmailVerificationCode.where(email: '$EMAIL').order(created_at: :desc).first
puts code.code if code
" 2>/dev/null | tail -1)
echo "验证码: $CODE"

# 5. 用户注册
echo ""
echo "=== 3. 用户注册 ==="
curl -X POST http://localhost:8080/api/mobile/register/register \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"code\": \"$CODE\",
    \"password\": \"Test123!@#\",
    \"nickname\": \"测试用户\"
  }" | jq

# 6. 用户登录
echo ""
echo "=== 4. 用户登录 ==="
curl -X POST http://localhost:8080/api/mobile/register/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"Test123!@#\"
  }" | jq
```

## 查看数据库验证码（用于测试）

如果需要查看发送的验证码进行测试：

```bash
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails runner "
codes = EmailVerificationCode.where(email: 'your-email@example.com').order(created_at: :desc).limit(5)
codes.each do |code|
  puts \"验证码: #{code.code}, 过期时间: #{code.expires_at}, 已使用: #{code.used}\"
end
"
```

## 常见错误处理

1. **验证码错误或已过期**
   - 检查验证码是否正确
   - 验证码有效期5分钟
   - 验证码使用后立即失效

2. **发送过于频繁**
   - 同一邮箱60秒内只能发送一次

3. **今日发送次数已达上限**
   - 同一邮箱每天最多发送10次

4. **邮箱已被注册**
   - 使用不同的邮箱进行测试

## 调试技巧

查看 Rails 日志：
```bash
docker-compose -f docker-compose.development.yaml logs rails --tail 50 -f
```

进入 Rails 控制台：
```bash
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails console
```

检查数据库：
```bash
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails dbconsole
```

