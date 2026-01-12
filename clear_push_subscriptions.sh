#!/bin/bash
# clear_push_subscriptions.sh
# 作用: 清除 Chatwoot 推送订阅信息
# 用法: 
#   ./clear_push_subscriptions.sh              # 清除所有订阅 (需确认)
#   ./clear_push_subscriptions.sh <email>      # 清除指定邮箱的订阅

EMAIL=$1

# 检查是否在 Chatwoot 目录
if [ ! -f "docker-compose.yaml" ]; then
  echo "❌ 请在 Chatwoot 根目录运行此脚本 (即包含 docker-compose.yaml 的目录)"
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "⚠️  【高危操作】您未指定邮箱，这将删除数据库中 **所有** 用户的推送订阅记录！"
  read -p "❓ 确定要彻底清空吗？(输入 y 确认): " confirm
  if [ "$confirm" != "y" ]; then
    echo "操作已取消。"
    exit 0
  fi
  
  echo "🧹 正在清除所有订阅..."
  docker-compose exec postgres psql -U postgres -d chatwoot -c "DELETE FROM contact_push_subscriptions;"
  echo "✅ 所有推送订阅已清除。"
else
  echo "🧹 正在清除账号 $EMAIL 的订阅..."
  # 使用子查询查找 contact_id 并删除
  SQL="DELETE FROM contact_push_subscriptions WHERE contact_id IN (SELECT id FROM contacts WHERE email = '$EMAIL' OR identifier = '$EMAIL');"
  
  # 执行并显示删除行数
  docker-compose exec postgres psql -U postgres -d chatwoot -c "$SQL"
  
  echo "✅ 账号 $EMAIL 的订阅已清除 (如果存在)。"
fi
