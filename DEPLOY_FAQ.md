# Chatwoot 部署常见问题解答

## 📌 关于缓存

### Q: 脚本会使用Docker缓存吗？

**答：是的！** 脚本会充分利用Docker的分层缓存机制。

### 缓存工作原理

```
Dockerfile的层次结构：
1. 基础镜像 (node:23-alpine, ruby:3.4.4-alpine3.21)  ← 使用缓存 ✓
2. 安装系统依赖 (apk add)                           ← 使用缓存 ✓
3. 安装Ruby gems (bundle install)                  ← 使用缓存 ✓
4. 安装npm包 (pnpm install)                        ← 使用缓存 ✓
5. 复制代码 (COPY . /app)                          ← 如果代码变了就重新执行 ✗
6. 编译assets (rake assets:precompile)            ← 重新执行 ✗
```

### 实际效果对比

| 场景 | 首次构建 | 有缓存 | 节省时间 |
|------|---------|--------|---------|
| 完全重建 | ~15分钟 | ~15分钟 | 0% |
| 仅修改前端代码 | ~15分钟 | ~3分钟 | 80% |
| 仅修改后端代码 | ~15分钟 | ~4分钟 | 73% |
| 添加新依赖 | ~15分钟 | ~8分钟 | 47% |

### 强制不使用缓存

如果需要完全重新构建（例如清理构建问题）：

```bash
./deploy_to_remote_advanced.sh --no-cache
```

---

## 📌 关于数据保留

### Q: 部署时数据库会被清空吗？

**答：不会！** 脚本使用 `docker-compose down`（不带 `-v` 参数），只停止容器，**完全保留**所有数据。

### 数据存储位置

所有数据存储在Docker volumes中：

```bash
# 查看数据卷
docker volume ls | grep chatwoot

输出：
chatwoot_postgres_data      # ← PostgreSQL数据库数据
chatwoot_redis_data         # ← Redis缓存数据  
chatwoot_storage_data       # ← 上传的文件和附件
```

### 数据持久化保证

| 数据类型 | 存储位置 | 是否保留 |
|---------|---------|---------|
| 数据库数据 | chatwoot_postgres_data | ✅ 保留 |
| Redis数据 | chatwoot_redis_data | ✅ 保留 |
| 上传文件 | chatwoot_storage_data | ✅ 保留 |
| 配置文件 | .env | ✅ 保留 |
| 容器本身 | - | ❌ 重新创建 |
| 镜像 | - | ✅ 更新 |

### 数据卷的生命周期

```bash
# 容器停止 → 数据保留
docker-compose down              ✅ 数据安全

# 容器删除 → 数据保留  
docker-compose down              ✅ 数据安全
docker rm chatwoot-rails-1       ✅ 数据安全

# 明确删除数据卷 → 数据丢失
docker-compose down -v           ⚠️ 数据会被删除！
docker volume rm chatwoot_postgres_data  ⚠️ 数据会被删除！
```

### 验证数据保留

```bash
# 部署前
ssh root@43.157.0.135 'docker exec chatwoot-postgres-1 psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM users;"'

# 部署后（数据应该相同）
ssh root@43.157.0.135 'docker exec chatwoot-postgres-1 psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM users;"'
```

---

## 📌 部署脚本对比

### 基础版 vs 增强版

| 功能 | deploy_to_remote.sh | deploy_to_remote_advanced.sh |
|------|-------------------|----------------------------|
| 自动构建 | ✅ | ✅ |
| 使用缓存 | ✅ | ✅ |
| 保留数据 | ✅ | ✅ |
| 压缩传输 | ✅ | ✅ |
| 跳过构建选项 | ❌ | ✅ |
| 强制重建选项 | ❌ | ✅ |
| 清理数据选项 | ❌ | ✅ |
| 帮助文档 | ❌ | ✅ |
| 详细日志 | ✅ | ✅ |

### 使用建议

**日常更新** → 使用基础版
```bash
./deploy_to_remote.sh
```

**需要特殊选项** → 使用增强版
```bash
# 查看帮助
./deploy_to_remote_advanced.sh --help

# 只部署，不重新构建
./deploy_to_remote_advanced.sh --skip-build

# 完全重建（清理缓存）
./deploy_to_remote_advanced.sh --no-cache
```

---

## 📌 数据备份建议

### 自动备份脚本

```bash
#!/bin/bash
# backup_chatwoot.sh

BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

ssh root@43.157.0.135 << 'EOF'
mkdir -p /root/backups
docker exec chatwoot-postgres-1 pg_dump -U postgres chatwoot > /root/backups/chatwoot_$DATE.sql
gzip /root/backups/chatwoot_$DATE.sql
echo "备份完成: chatwoot_$DATE.sql.gz"
ls -lh /root/backups/
