# DBeaver 连接 Chatwoot 数据库指南

我已经为您在 Docker 中开放了数据库端口 **5432**。您现在可以使用 DBeaver 按照以下配置进行连接：

## 📋 连接配置信息

| 参数项 | 配置值 |
| :--- | :--- |
| **数据库类型** | PostgreSQL |
| **服务器地址 (Host)** | `172.18.88.87` (或使用您的服务器公网/内网 IP) |
| **端口 (Port)** | `5432` |
| **数据库名 (Database)** | `chatwoot` |
| **用户名 (Username)** | `postgres` |
| **密码 (Password)** | `chatwoot_postgres_password` |

---

## 🔧 DBeaver 操作步骤

1. **新建连接**:
   - 在 DBeaver 中点击左上角的“新连接”图标。
   - 选择 **PostgreSQL**。

2. **填写设置**:
   - 在 **Main** 选项卡中，将上述表格中的 Host、Database、Username、Password 填入对应框内。
   - 点击底部的 **Test Connection... (测试连接)**。

3. **下载驱动**:
   - 如果 DBeaver 提示缺少驱动，点击 **Download** 让它自动下载即可。

4. **完成连接**:
   - 测试通过后点击 **Finish**。您现在可以查看所有的表（如 `users`, `contacts`, `messages` 等）。

---

## 🛠️ 备注 (运维参考)

如果您是在生产服务器上操作，请注意：
- 我已经在 `docker-compose.yaml` 中添加了 `ports: - '5432:5432'` 并重启了数据库服务。
- 数据库账号密码来源于项目根目录的 `.env` 文件。
- 如果您无法连接，请检查服务器的防火墙（Security Group）是否放行了 **5432** 端口。

---

## 常用表查询命令 (SQL)

连接成功后，您可以尝试运行以下 SQL 来查看数据：

```sql
-- 查看所有注册用户及其余额
SELECT id, email, name, balance, last_check_in_at FROM users WHERE type IS NULL;

-- 查看今日签到记录
SELECT * FROM users WHERE last_check_in_at >= CURRENT_DATE;
```
