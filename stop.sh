#!/bin/bash
# 停止 Chatwoot 服务

echo "🛑 停止 Chatwoot 服务..."

docker-compose -f docker-compose.production.yaml down

echo "✅ 服务已停止"

