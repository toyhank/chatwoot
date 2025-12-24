# Chatwoot Production 远程部署指南

## 📋 概述

本脚本用于自动化构建和部署Chatwoot到远程生产服务器。

## 🚀 快速开始

### 1. 前置要求

- 已配置SSH密钥登录到远程服务器
- 远程服务器已安装Docker和Docker Compose
- 本地已安装Docker

### 2. 使用方法

```bash
# 进入项目目录
cd /home/chatwoot1/chatwoot

# 运行部署脚本
./deploy_to_remote.sh
```

## 📝 脚本功能

脚本会自动执行以下步骤：

1. **环境检查** - 检查必要的命令是否存在
2. **构建镜像** - 使用Dockerfile构建production镜像
3. **压缩镜像** - 导出并压缩Docker镜像（节省传输时间）
4. **SSH连接测试** - 确认能够连接到远程服务器
5. **文件传输** - 传输配置文件和Docker镜像
6. **远程部署** - 在服务器上导入镜像并启动容器
7. **健康检查** - 验证服务是否正常运行
8. **清理** - 删除临时文件

## ⚙️ 配置

如需修改部署目标服务器，编辑脚本中的配置变量：

```bash
REMOTE_SERVER="43.157.0.135"    # 远程服务器IP
REMOTE_USER="root"              # SSH用户
REMOTE_DIR="/root/chatwoot"     # 远程部署目录
```

## 🔧 常用命令

### 查看远程日志
```bash
ssh root@43.157.0.135 'cd /root/chatwoot && docker-compose -f docker-compose.production.yaml logs -f'
```

### 重启服务
```bash
ssh root@43.157.0.135 'cd /root/chatwoot && docker-compose -f docker-compose.production.yaml restart'
```

### 查看容器状态
```bash
ssh root@43.157.0.135 'cd /root/chatwoot && docker-compose -f docker-compose.production.yaml ps'
```

### 停止服务
```bash
ssh root@43.157.0.135 'cd /root/chatwoot && docker-compose -f docker-compose.production.yaml down'
```

### 备份数据库
```bash
ssh root@43.157.0.135 'docker exec chatwoot-postgres-1 pg_dump -U postgres chatwoot > /root/chatwoot_backup_$(date +%Y%m%d).sql'
```

## 🔐 访问信息

部署完成后：

- **访问地址**: http://43.157.0.135:8080
- **默认邮箱**: admin@example.com
- **默认密码**: Chatwoot123!

⚠️ 首次登录后请立即修改密码！

## 📊 数据持久化

数据存储在Docker volumes中，容器重启不会丢失数据：

- `chatwoot_postgres_data` - 数据库数据
- `chatwoot_redis_data` - Redis数据
- `chatwoot_storage_data` - 文件存储

## 🐛 故障排查

### 问题：SSH连接失败
```bash
# 检查SSH密钥
ssh -v root@43.157.0.135
```

### 问题：容器启动失败
```bash
# 查看详细日志
ssh root@43.157.0.135 'cd /root/chatwoot && docker-compose -f docker-compose.production.yaml logs'
```

### 问题：数据库连接失败
```bash
# 重置数据库密码
ssh root@43.157.0.135 "docker exec chatwoot-postgres-1 psql -U postgres -c \"ALTER USER postgres WITH PASSWORD 'chatwoot_postgres_password';\""
```

## 📦 镜像大小优化

脚本会自动压缩镜像：
- 原始大小: ~1.8GB
- 压缩后: ~664MB
- 节省: ~63%

## 🔄 更新流程

当你修改代码后，只需再次运行脚本即可自动部署更新：

```bash
./deploy_to_remote.sh
```

脚本会：
1. 重新构建包含最新代码的镜像
2. 传输到服务器
3. 停止旧容器
4. 启动新容器（数据会自动保留）

## ⚡ 性能建议

1. 首次部署较慢（需要传输1.8GB数据），后续更新会利用Docker缓存，只重建修改的层
2. 建议在网络状况良好时进行部署
3. 如果只修改了前端代码，构建时间会大幅减少（利用缓存）

## 📞 支持

如遇问题，请检查：
1. SSH配置是否正确
2. 远程服务器Docker服务是否运行
3. 网络连接是否稳定
4. 磁盘空间是否充足（至少需要5GB）

---

**最后更新**: 2025-12-24
