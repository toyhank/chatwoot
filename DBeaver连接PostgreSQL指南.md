# DBeaver 连接 Chatwoot PostgreSQL 指南

## 📋 连接信息

根据 `docker-compose.development.yaml` 和 `.env.develop` 配置：

| 参数 | 值 |
|------|-----|
| **Host** | `localhost` 或 `127.0.0.1` |
| **Port** | `5432` |
| **Database** | `chatwoot` |
| **Username** | `postgres` |
| **Password** | `postgres` |
| **PostgreSQL Version** | 16 (pgvector/pgvector:pg16) |

## 🔧 DBeaver 配置步骤

### 1. 创建新连接

1. 打开 DBeaver
2. 点击 **Database** → **New Database Connection**
3. 选择 **PostgreSQL**
4. 点击 **Next**

### 2. 填写连接信息

**Main 标签**：
```
Host: localhost
Port: 5432
Database: chatwoot
Username: postgres
Password: postgres
```

**勾选选项**：
- ✅ Show all databases

### 3. 驱动设置（可选）

点击 **Edit Driver Settings**，确保：
- Driver name: PostgreSQL
- Class Name: org.postgresql.Driver
- URL Template: `jdbc:postgresql://{ho
st}:{port}/{database}`

### 4. 测试连接

点击 **Test Connection**，应该显示：
```
Connected
PostgreSQL 16.x
Driver: PostgreSQL JDBC Driver
```

### 5. 完成

点击 **Finish** 保存连接。

---

## ⚠️ 故障排查

### 问题 1: 连接被拒绝 (Connection refused)

**原因**: Docker 端口没有映射到主机

**解决方案**:

1. **检查端口映射**:
```bash
docker ps --filter "name=postgres" --format "table {{.Names}}\t{{.Ports}}"
```

应该看到：`0.0.0.0:5432->5432/tcp`

2. **如果没有映射，重启 PostgreSQL**:
```bash
cd /home/chatwoot1/chatwoot
docker compose -f docker-compose.development.yaml restart postgres
```

3. **验证端口映射**:
```bash
docker compose -f docker-compose.development.yaml port postgres 5432
```

应该返回：`0.0.0.0:5432` 或 `127.0.0.1:5432`

### 问题 2: 端口 5432 被占用

**检查端口占用**:
```powershell
netstat -ano | findstr :5432
```

**解决方案 A**: 停止占用端口的程序

**解决方案 B**: 修改 PostgreSQL 端口

编辑 `docker-compose.development.yaml`：
```yaml
postgres:
  ports:
    - '5433:5432'  # 改为 5433
```

然后在 DBeaver 中使用 `Port: 5433`

### 问题 3: 密码认证失败

**检查密码**：
```bash
docker compose -f docker-compose.development.yaml exec postgres psql -U postgres -c "\conninfo"
```

**重置密码**（如果需要）：
```bash
docker compose -f docker-compose.development.yaml exec postgres psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

### 问题 4: Docker Desktop 未启动

确保 Docker Desktop 正在运行：
```bash
docker ps
```

如果返回错误，启动 Docker Desktop。

---

## 🎯 快速测试连接

使用命令行测试：

```bash
# Windows (如果安装了 PostgreSQL 客户端)
psql -h localhost -p 5432 -U postgres -d chatwoot

# 或使用 Docker
docker compose -f docker-compose.development.yaml exec postgres psql -U postgres -d chatwoot
```

成功连接后会看到：
```
psql (16.x)
Type "help" for help.

chatwoot=#
```

---

## 📊 常用查询

连接成功后，可以运行：

```sql
-- 查看所有表
\dt

-- 查看数据库大小
SELECT pg_size_pretty(pg_database_size('chatwoot'));

-- 查看所有 Contacts
SELECT id, name, email, identifier FROM contacts LIMIT 10;

-- 查看推送订阅
SELECT id, contact_id, contact_inbox_id, LEFT(push_token, 40) as token, platform 
FROM contact_push_subscriptions;

-- 查看最近的消息
SELECT m.id, m.content, m.message_type, m.created_at, c.contact_id 
FROM messages m 
JOIN conversations c ON c.id = m.conversation_id 
ORDER BY m.created_at DESC 
LIMIT 10;
```

---

## 🔒 安全提示

⚠️ **生产环境注意事项**：

1. **不要在生产环境暴露 5432 端口**
2. **使用强密码**（当前密码是 `postgres`，仅用于开发）
3. **限制访问 IP**（如需要，在 docker-compose.yaml 中配置）

生产环境建议配置：
```yaml
postgres:
  ports:
    - '127.0.0.1:5432:5432'  # 只允许本地访问
  environment:
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # 使用环境变量
```

---

## 📚 相关文件

- [docker-compose.development.yaml](file:///home/chatwoot1/chatwoot/docker-compose.development.yaml) - Docker 配置
- [.env.develop](file:///home/chatwoot1/chatwoot/.env.develop) - 环境变量配置

---

## ✅ 连接成功标准

成功连接后，在 DBeaver 中应该能看到：

```
📁 chatwoot
  📁 Schemas
    📁 public
      📁 Tables
        📄 accounts
        📄 contacts
        📄 contact_push_subscriptions
        📄 conversations
        📄 messages
        ... (更多表)
```
