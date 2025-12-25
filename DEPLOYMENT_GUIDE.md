# Chatwoot 多环境部署说明

## 📋 问题说明

在生产环境打包时，图片无法发送的原因是 `FRONTEND_URL` 配置为 `http://localhost:3000`，导致生成的图片 URL 无法在其他机器上访问。

## 🎯 解决方案

本项目现已配置多环境支持，可以轻松在本地和服务器之间切换。

## 📁 文件说明

- `.env.local` - 本地开发环境配置（FRONTEND_URL=http://localhost:3000）
- `.env.production.local` - 服务器生产环境配置（需要配置实际的服务器IP/域名）
- `.env` - 当前激活的配置（由启动脚本自动生成）
- `start-local.sh` - 本地环境启动脚本
- `start-server.sh` - 服务器环境启动脚本
- `stop.sh` - 停止服务脚本

## 🚀 使用方法

### 首次配置（重要）

**1. 配置服务器生产环境**

编辑 `.env.production.local` 文件，将 `YOUR_SERVER_IP` 替换为实际值：

```bash
# 方式1: 如果有域名（推荐）
FRONTEND_URL=https://your-domain.com

# 方式2: 如果使用服务器IP
FRONTEND_URL=http://192.168.1.100:8080

# 方式3: 如果使用服务器IP和默认端口
FRONTEND_URL=http://192.168.1.100:8080
```

**编辑命令：**
```bash
nano .env.production.local
# 或
vim .env.production.local
```

### 在本地运行（使用 localhost）

```bash
# 启动本地环境
./start-local.sh

# 访问地址
http://localhost:8080
```

### 在服务器运行（使用服务器IP）

```bash
# 启动服务器环境
./start-server.sh

# 访问地址（根据您的配置）
http://YOUR_SERVER_IP:8080
```

### 停止服务

```bash
./stop.sh
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.production.yaml logs -f

# 只查看 Rails 日志
docker-compose -f docker-compose.production.yaml logs -f rails

# 只查看 Sidekiq 日志
docker-compose -f docker-compose.production.yaml logs -f sidekiq
```

### 重启服务（保持当前配置）

```bash
docker-compose -f docker-compose.production.yaml restart
```

## 🔍 故障排查

### 1. 图片仍然无法显示

**检查当前配置：**
```bash
grep FRONTEND_URL .env
```

**应该显示：**
- 本地环境: `FRONTEND_URL=http://localhost:3000`
- 服务器环境: `FRONTEND_URL=http://YOUR_ACTUAL_IP:8080`

### 2. 确认服务是否正常运行

```bash
docker-compose -f docker-compose.production.yaml ps
```

### 3. 查看最新的错误日志

```bash
docker-compose -f docker-compose.production.yaml logs --tail=50 rails
```

### 4. 完全重启（清理并重新启动）

```bash
./stop.sh
docker-compose -f docker-compose.production.yaml down -v
# 然后根据环境选择：
./start-local.sh    # 或
./start-server.sh
```

## ⚙️ 高级配置

### 使用 HTTPS（生产环境强烈推荐）

在 `.env.production.local` 中添加：

```bash
FRONTEND_URL=https://your-domain.com
FORCE_SSL=true
```

**注意：** 需要配置 Nginx 或其他反向代理来处理 SSL 证书。

### 使用云存储（S3）

在 `.env.production.local` 中添加：

```bash
ACTIVE_STORAGE_SERVICE=amazon
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET_NAME=your-bucket-name
```

### 修改文件上传大小限制

在 `.env` 中添加：

```bash
# 单位：MB，默认 40MB
MAXIMUM_FILE_UPLOAD_SIZE=100
```

## 📝 快速参考

| 场景 | 命令 |
|------|------|
| 本地开发 | `./start-local.sh` |
| 服务器部署 | `./start-server.sh` |
| 停止服务 | `./stop.sh` |
| 查看日志 | `docker-compose -f docker-compose.production.yaml logs -f` |
| 重启服务 | `docker-compose -f docker-compose.production.yaml restart` |
| 查看状态 | `docker-compose -f docker-compose.production.yaml ps` |

## ⚠️ 注意事项

1. **首次使用前必须配置 `.env.production.local`** 中的 `FRONTEND_URL`
2. 本地和服务器使用**相同的数据库**（通过 Docker volumes 持久化）
3. 切换环境后需要重启服务才能生效
4. 不要直接编辑 `.env` 文件，它会被启动脚本覆盖
5. `.env.local` 和 `.env.production.local` 应该添加到 `.gitignore`（如果包含敏感信息）

## 🔐 安全建议

1. 生产环境使用 HTTPS
2. 修改默认的数据库密码
3. 使用强密码（`SECRET_KEY_BASE` 已自动生成）
4. 定期备份数据库和存储文件
5. 不要将包含敏感信息的 `.env` 文件提交到 Git

## 📞 获取帮助

如果遇到问题：

1. 查看日志: `docker-compose -f docker-compose.production.yaml logs -f rails`
2. 检查配置: `cat .env | grep FRONTEND_URL`
3. 查看容器状态: `docker-compose -f docker-compose.production.yaml ps`
4. 检查端口占用: `netstat -tulpn | grep 8080`

