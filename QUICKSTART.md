# 🚀 快速开始

## 问题：生产环境无法发送图片

**原因**：`FRONTEND_URL` 配置为 `localhost`，导致图片 URL 无法在其他机器访问。

**解决方案**：使用不同的环境配置文件。

---

## ⚡ 三步解决

### 1️⃣ 运行配置向导

```bash
./setup-env.sh
```

按提示选择：
- **选项 1**：本地开发（使用 localhost）
- **选项 2**：服务器部署（需要输入服务器IP或域名）

### 2️⃣ 启动服务

**本地环境：**
```bash
./start-local.sh
```
访问：http://localhost:8080

**服务器环境：**
```bash
./start-server.sh
```
访问：http://YOUR_SERVER_IP:8080

### 3️⃣ 测试图片上传

启动后，在 Chatwoot 中测试上传图片，应该可以正常显示。

---

## 📋 手动配置（可选）

如果不使用向导，可以手动配置：

### 方式 1：编辑配置文件

```bash
# 编辑服务器配置
nano .env.production.local
```

修改第 3 行：
```bash
# 改为您的实际地址，例如：
FRONTEND_URL=http://192.168.1.100:8080
# 或
FRONTEND_URL=https://your-domain.com
```

然后运行：
```bash
./start-server.sh
```

### 方式 2：一键修改

```bash
# 替换为您的实际IP
sed -i 's|YOUR_SERVER_IP|192.168.1.100|g' .env.production.local
./start-server.sh
```

---

## 🛠️ 常用命令

| 操作 | 命令 |
|------|------|
| **配置环境** | `./setup-env.sh` |
| **启动（本地）** | `./start-local.sh` |
| **启动（服务器）** | `./start-server.sh` |
| **停止服务** | `./stop.sh` |
| **查看日志** | `docker-compose -f docker-compose.production.yaml logs -f` |
| **查看当前配置** | `grep FRONTEND_URL .env` |

---

## 🔍 验证配置

### 检查当前使用的 URL：

```bash
grep FRONTEND_URL .env
```

**应该显示：**
- 本地：`FRONTEND_URL=http://localhost:3000`
- 服务器：`FRONTEND_URL=http://YOUR_ACTUAL_IP:8080`

### 查看服务状态：

```bash
docker-compose -f docker-compose.production.yaml ps
```

### 查看 Rails 日志：

```bash
docker-compose -f docker-compose.production.yaml logs -f rails | grep -i "storage\|upload\|attachment"
```

---

## 💡 提示

1. **首次使用前必须运行** `./setup-env.sh` 或手动配置 `.env.production.local`
2. **切换环境后需要重启**服务才能生效
3. **日志中应该显示正确的 URL**，例如：
   ```
   data_url: "http://YOUR_SERVER_IP:8080/rails/active_storage/..."
   ```
   而不是 `http://localhost:3000/...`

---

## 📖 详细文档

查看完整部署指南：
```bash
cat DEPLOYMENT_GUIDE.md
```

---

## ⚠️ 常见问题

### 问题：图片仍然显示 localhost URL

**解决：**
```bash
./stop.sh
./start-server.sh  # 或 ./start-local.sh
```

### 问题：端口 8080 被占用

**解决：**
```bash
# 查看占用端口的进程
sudo netstat -tulpn | grep 8080

# 或修改 docker-compose.production.yaml 中的端口映射
```

### 问题：无法访问服务器 IP

**检查：**
1. 防火墙是否开放 8080 端口
2. 服务器 IP 地址是否正确
3. 网络连接是否正常

```bash
# 在服务器上检查端口监听
sudo netstat -tulpn | grep 8080

# 检查防火墙（Ubuntu/Debian）
sudo ufw status
sudo ufw allow 8080
```

