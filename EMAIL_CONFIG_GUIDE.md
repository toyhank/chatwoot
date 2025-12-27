# Chatwoot 邮件服务配置指南

## 概述

Chatwoot 支持多种邮件发送方式，包括：
- SMTP 服务器
- MailHog（开发环境）
- Letter Opener（开发环境）

## 配置方式

邮件配置通过环境变量进行设置。在 Docker 环境中，可以通过 `.env` 文件或 `docker-compose.yaml` 中的环境变量配置。

## 环境变量配置

### SMTP 配置（推荐用于生产环境）

```bash
# SMTP 服务器地址
SMTP_ADDRESS=smtp.gmail.com

# SMTP 端口（通常是 587 用于 TLS，465 用于 SSL，25 用于不加密）
SMTP_PORT=587

# SMTP 认证方式（通常是 'login'）
SMTP_AUTHENTICATION=login

# SMTP 用户名
SMTP_USERNAME=your-email@gmail.com

# SMTP 密码（Gmail 需要使用应用专用密码）
SMTP_PASSWORD=your-app-password

# SMTP 域名（可选）
SMTP_DOMAIN=gmail.com

# 启用 STARTTLS（通常为 true）
SMTP_ENABLE_STARTTLS_AUTO=true

# 使用 SSL（端口 465 时使用）
SMTP_SSL=false

# 使用 TLS（端口 587 时使用）
SMTP_TLS=true

# 邮件发送者地址
MAILER_SENDER_EMAIL=Chatwoot <noreply@yourdomain.com>
```

### 开发环境配置

#### 方式 1: 使用 MailHog（推荐）

MailHog 是一个开发环境的邮件测试工具，可以捕获所有发送的邮件。

**配置步骤：**

1. 确保 `docker-compose.development.yaml` 中已包含 MailHog 服务（通常已包含）

2. 设置环境变量：
```bash
# 不设置 SMTP_ADDRESS，系统会自动使用 sendmail
# 或者设置为 MailHog 的地址
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
MAILER_SENDER_EMAIL=Chatwoot <test@example.com>
```

3. 访问 MailHog Web UI：http://localhost:8025

**MailHog 特点：**
- 自动捕获所有发送的邮件
- 提供 Web 界面查看邮件
- 不需要真实的 SMTP 服务器
- 适合开发和测试

#### 方式 2: 使用 Letter Opener（Rails 开发）

Letter Opener 会在浏览器中打开邮件，而不是真正发送。

```bash
# 启用 Letter Opener
LETTER_OPENER=true
```

## 常用邮件服务商配置示例

### Gmail

```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # 需要使用应用专用密码
SMTP_DOMAIN=gmail.com
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=true
SMTP_SSL=false
MAILER_SENDER_EMAIL=Your Name <your-email@gmail.com>
```

**注意**：Gmail 需要使用[应用专用密码](https://support.google.com/accounts/answer/185833)，不能使用普通密码。

### Outlook/Office 365

```bash
SMTP_ADDRESS=smtp.office365.com
SMTP_PORT=587
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=true
SMTP_SSL=false
MAILER_SENDER_EMAIL=Your Name <your-email@outlook.com>
```

### SendGrid

```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_AUTHENTICATION=login
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=true
MAILER_SENDER_EMAIL=Your Name <noreply@yourdomain.com>
```

### Mailgun

```bash
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=true
MAILER_SENDER_EMAIL=Your Name <noreply@yourdomain.com>
```

### 阿里云邮件推送

```bash
SMTP_ADDRESS=smtpdm.aliyun.com
SMTP_PORT=465
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-email@yourdomain.com
SMTP_PASSWORD=your-smtp-password
SMTP_SSL=true
SMTP_TLS=false
MAILER_SENDER_EMAIL=Your Name <your-email@yourdomain.com>
```

### 腾讯企业邮箱

```bash
SMTP_ADDRESS=smtp.exmail.qq.com
SMTP_PORT=465
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-email@yourdomain.com
SMTP_PASSWORD=your-password
SMTP_SSL=true
SMTP_TLS=false
MAILER_SENDER_EMAIL=Your Name <your-email@yourdomain.com>
```

## Docker 环境配置

### 方式 1: 使用 .env 文件（推荐）

1. 创建或编辑 `.env` 文件：

```bash
# 编辑 .env 文件
nano .env
```

2. 添加邮件配置：

```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_AUTHENTICATION=login
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_TLS=true
MAILER_SENDER_EMAIL=Chatwoot <noreply@yourdomain.com>
```

3. 重启服务：

```bash
docker-compose -f docker-compose.development.yaml restart rails
```

### 方式 2: 在 docker-compose.yaml 中配置

编辑 `docker-compose.development.yaml`，在 `rails` 服务的 `environment` 部分添加：

```yaml
services:
  rails:
    environment:
      - SMTP_ADDRESS=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_AUTHENTICATION=login
      - SMTP_USERNAME=your-email@gmail.com
      - SMTP_PASSWORD=your-app-password
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_TLS=true
      - MAILER_SENDER_EMAIL=Chatwoot <noreply@yourdomain.com>
```

## 验证配置

### 1. 检查环境变量

```bash
# 在 Docker 容器中检查
docker-compose -f docker-compose.development.yaml exec rails env | grep SMTP
```

### 2. 测试邮件发送

使用 Rails 控制台测试：

```bash
docker-compose -f docker-compose.development.yaml exec rails bundle exec rails console

# 在控制台中运行
RegisterMailer.verification_code('test@example.com', '123456', 5).deliver_now
```

### 3. 查看邮件日志

```bash
# 查看 Rails 日志
docker-compose -f docker-compose.development.yaml logs rails | grep -i mail

# 如果使用 MailHog，访问 Web UI
# http://localhost:8025
```

## 当前开发环境配置（MailHog）

如果你使用 Docker Compose 开发环境，MailHog 通常已经配置好：

1. **访问 MailHog Web UI**: http://localhost:8025
2. **所有发送的邮件会自动捕获**，无需额外配置
3. **不需要设置 SMTP 环境变量**

## 常见问题

### 1. 邮件发送失败

**检查项：**
- SMTP 服务器地址和端口是否正确
- 用户名和密码是否正确
- 是否启用了正确的 TLS/SSL 设置
- 防火墙是否阻止了 SMTP 端口

**错误处理：**
- 查看 Rails 日志：`docker-compose logs rails | grep -i mail`
- 检查邮件配置：确保所有必需的 SMTP 参数都已设置

### 2. Gmail 认证失败

**解决方案：**
- 启用 Google 账户的"允许不够安全的应用"
- 或使用[应用专用密码](https://support.google.com/accounts/answer/185833)

### 3. 邮件进入垃圾箱

**解决方案：**
- 配置 SPF 记录
- 配置 DKIM 签名
- 使用专业的邮件服务（如 SendGrid、Mailgun）
- 确保 `MAILER_SENDER_EMAIL` 使用已验证的域名

### 4. 开发环境邮件未发送

**原因：**
- 如果 `SMTP_ADDRESS` 未设置，系统会尝试使用 sendmail
- Docker 容器中通常没有 sendmail

**解决方案：**
- 使用 MailHog（推荐）
- 或配置 SMTP 服务器
- 或启用 Letter Opener：`LETTER_OPENER=true`

## 邮箱注册登录功能的邮件配置

对于邮箱注册登录功能，确保：

1. **邮件服务已正确配置**（可以使用 MailHog 进行开发测试）
2. **`MAILER_SENDER_EMAIL` 已设置**
3. **验证码邮件模板存在**：`app/views/mailers/register_mailer/verification_code.html.erb`

**测试邮件发送：**

```bash
# 发送测试验证码
curl -X POST http://localhost:8080/api/mobile/register/send_code \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# 如果使用 MailHog，访问 http://localhost:8025 查看邮件
```

## 安全建议

1. **不要在代码中硬编码密码**
2. **使用环境变量或密钥管理服务**
3. **生产环境使用专业的邮件服务**（SendGrid、Mailgun、Amazon SES）
4. **定期轮换密码和 API 密钥**
5. **启用 TLS/SSL 加密**

