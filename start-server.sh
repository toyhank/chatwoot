#!/bin/bash
# 服务器生产环境启动脚本

echo "🚀 启动服务器 Chatwoot 环境..."

# 检查是否已配置服务器IP
if grep -q "YOUR_SERVER_IP" .env.production.local; then
    echo "⚠️  警告: 请先编辑 .env.production.local 文件，将 YOUR_SERVER_IP 替换为实际的服务器IP或域名"
    echo "例如: FRONTEND_URL=http://192.168.1.100:8080"
    echo "或者: FRONTEND_URL=https://your-domain.com"
    exit 1
fi

# 使用服务器配置
cp .env.production.local .env

echo "✅ 已切换到服务器配置"
grep "FRONTEND_URL" .env

# 启动服务
docker-compose -f docker-compose.production.yaml up -d

echo "✅ 服务器环境已启动"

