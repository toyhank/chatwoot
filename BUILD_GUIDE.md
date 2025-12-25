# 📦 Chatwoot 生产镜像构建指南

## 🚀 快速开始

### 方法 1：使用自动化脚本（推荐）⭐

```bash
cd /home/chatwoot1/chatwoot
./build_production.sh
```

这个脚本会：
- ✅ 自动清理旧构建
- ✅ 构建生产镜像
- ✅ 创建多个标签
- ✅ 可选导出为 .tar.gz

---

### 方法 2：使用 Makefile

```bash
cd /home/chatwoot1/chatwoot
make docker
```

生成镜像：`chatwoot:latest`

---

### 方法 3：Docker 命令

#### 基础构建
```bash
docker build -f docker/Dockerfile -t chatwoot/chatwoot:production .
```

#### 多标签构建
```bash
docker build -f docker/Dockerfile \
  -t chatwoot/chatwoot:production \
  -t chatwoot/chatwoot:v4.9.1 \
  -t chatwoot/chatwoot:latest \
  .
```

#### 无缓存构建（全新构建）
```bash
docker build --no-cache -f docker/Dockerfile -t chatwoot/chatwoot:production .
```

---

## 📋 构建过程说明

### 构建阶段

1. **Pre-builder 阶段**（基于 Ruby 3.4.4 + Node 23）
   - 安装系统依赖
   - 安装 Ruby gems
   - 安装 npm 包（pnpm）
   - 预编译前端资源（Vite）
   - 预编译后端资源（Rails assets）

2. **Final 阶段**（精简镜像）
   - 只复制必要的运行时文件
   - 移除开发依赖和缓存
   - 生成最终镜像

### 构建时间

- **首次构建**：15-30 分钟（取决于网络和机器性能）
- **增量构建**：5-10 分钟（利用 Docker 缓存）

### 镜像大小

- **未压缩**：约 1.8 GB
- **压缩后**：约 600-700 MB

---

## 📤 导出和传输镜像

### 导出镜像

```bash
# 导出为 tar 文件
docker save chatwoot/chatwoot:production -o chatwoot-production.tar

# 导出并压缩
docker save chatwoot/chatwoot:production | gzip > chatwoot-production.tar.gz
```

### 传输到远程服务器

```bash
# 使用 scp
scp chatwoot-production.tar.gz user@remote-server:/tmp/

# 使用 rsync
rsync -avz --progress chatwoot-production.tar.gz user@remote-server:/tmp/
```

### 在远程服务器加载镜像

```bash
# 加载 tar 文件
docker load < chatwoot-production.tar

# 加载压缩文件
docker load < chatwoot-production.tar.gz
```

---

## 🔧 高级选项

### 自定义构建参数

```bash
docker build -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg NODE_ENV=production \
  --build-arg BUNDLE_WITHOUT="development:test" \
  -t chatwoot/chatwoot:production \
  .
```

### 指定平台构建

```bash
# 为 ARM64 构建
docker build --platform linux/arm64 -f docker/Dockerfile -t chatwoot/chatwoot:production-arm64 .

# 为 AMD64 构建
docker build --platform linux/amd64 -f docker/Dockerfile -t chatwoot/chatwoot:production-amd64 .

# 多平台构建（需要 buildx）
docker buildx build --platform linux/amd64,linux/arm64 \
  -f docker/Dockerfile \
  -t chatwoot/chatwoot:production \
  --push .
```

---

## 🐛 故障排查

### 问题 1：构建内存不足

**症状**：构建过程中出现 "Killed" 或 "out of memory"

**解决方案**：
```bash
# 增加 Docker 内存限制（Docker Desktop）
# 或者减少并发构建
docker build -f docker/Dockerfile \
  --build-arg NODE_OPTIONS="--max-old-space-size=2048" \
  -t chatwoot/chatwoot:production .
```

### 问题 2：网络超时

**症状**：npm install 或 bundle install 失败

**解决方案**：
```bash
# 使用国内镜像源
docker build -f docker/Dockerfile \
  --network=host \
  -t chatwoot/chatwoot:production .
```

### 问题 3：缓存问题

**症状**：代码更新后镜像没有变化

**解决方案**：
```bash
# 清除构建缓存
docker builder prune -a

# 无缓存构建
docker build --no-cache -f docker/Dockerfile -t chatwoot/chatwoot:production .
```

### 问题 4：空间不足

**症状**：磁盘空间不足

**解决方案**：
```bash
# 清理未使用的镜像
docker image prune -a

# 清理所有未使用的资源
docker system prune -a --volumes
```

---

## ✅ 验证镜像

### 检查镜像大小

```bash
docker images chatwoot/chatwoot
```

### 测试运行

```bash
docker run --rm -it -p 3000:3000 \
  -e SECRET_KEY_BASE=test \
  -e POSTGRES_HOST=postgres \
  -e REDIS_URL=redis://redis:6379 \
  chatwoot/chatwoot:production \
  bundle exec rails console
```

### 检查镜像内容

```bash
# 进入镜像
docker run --rm -it chatwoot/chatwoot:production sh

# 检查版本
docker run --rm chatwoot/chatwoot:production cat /app/.git_sha
```

---

## 📊 构建优化建议

### 1. 使用 BuildKit

```bash
# 启用 BuildKit
export DOCKER_BUILDKIT=1
docker build -f docker/Dockerfile -t chatwoot/chatwoot:production .
```

### 2. 使用构建缓存

```bash
# 使用外部缓存
docker build \
  --cache-from chatwoot/chatwoot:production \
  -f docker/Dockerfile \
  -t chatwoot/chatwoot:production \
  .
```

### 3. 多阶段构建优化

Dockerfile 已经使用了多阶段构建，可以通过以下方式进一步优化：

```bash
# 只构建特定阶段
docker build --target pre-builder -f docker/Dockerfile -t chatwoot-builder .
```

---

## 📝 CI/CD 集成

### GitHub Actions 示例

```yaml
name: Build Production Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build and export
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./docker/Dockerfile
          tags: chatwoot/chatwoot:production
          outputs: type=docker,dest=/tmp/chatwoot.tar
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: chatwoot-image
          path: /tmp/chatwoot.tar
```

---

## 🔗 相关命令

```bash
# 查看镜像历史
docker history chatwoot/chatwoot:production

# 查看镜像详情
docker inspect chatwoot/chatwoot:production

# 推送到 Docker Hub（需要登录）
docker push chatwoot/chatwoot:production

# 标记为新版本
docker tag chatwoot/chatwoot:production chatwoot/chatwoot:v4.9.1

# 保存多个镜像
docker save -o chatwoot-bundle.tar \
  chatwoot/chatwoot:production \
  pgvector/pgvector:pg16 \
  redis:alpine
```

---

## 📞 需要帮助？

如遇问题：
1. 检查 Docker 版本：`docker --version`（推荐 20.10+）
2. 检查磁盘空间：`df -h`（至少需要 10GB）
3. 检查内存：`free -h`（推荐 8GB+）
4. 查看构建日志：添加 `--progress=plain` 参数

---

**最后更新**：2025-12-25
**Chatwoot 版本**：4.9.1

