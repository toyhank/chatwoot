#!/bin/bash
# 本地环境启动脚本

echo "🚀 启动本地 Chatwoot 环境..."

# 使用本地配置
cp .env.local .env

echo "✅ 已切换到本地配置 (FRONTEND_URL=http://localhost:3000)"

# 启动服务
docker-compose -f docker-compose.production.yaml up -d

echo "✅ 本地环境已启动"
echo "📝 访问地址: http://localhost:8080"

