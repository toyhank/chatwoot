#!/bin/bash
# Chatwoot Widget Push Notification API 测试脚本

# 禁用代理（本地访问不需要代理）
export NO_PROXY=127.0.0.1,localhost
export no_proxy=127.0.0.1,localhost

# 配置
WEBSITE_TOKEN="${1:-YOUR_WEBSITE_TOKEN}"
BASE_URL="${2:-http://127.0.0.1:8080}"

echo "🚀 开始测试 Chatwoot Widget Push API"
echo "📍 服务器: $BASE_URL"
echo ""

# 步骤1: 初始化 Widget
echo "📝 步骤 1: 初始化 Widget 并创建 Contact..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\"
  }")

echo "响应: $RESPONSE"
echo ""

# 提取 token（不使用 jq）
# 响应格式: {"website_channel_config":{"auth_token":"..."}}
AUTH_TOKEN=$(echo "$RESPONSE" | grep -o '"auth_token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$AUTH_TOKEN" == "null" ] || [ -z "$AUTH_TOKEN" ]; then
  echo "❌ 错误: 无法获取 auth token"
  echo "请检查:"
  echo "  1. WEBSITE_TOKEN 是否正确"
  echo "  2. 服务器是否正常运行"
  echo "  3. 是否创建了 Website Channel"
  exit 1
fi

echo "✅ 获取到 Auth Token: ${AUTH_TOKEN:0:20}..."
echo ""

# 步骤2: 注册推送订阅
echo "📝 步骤 2: 注册推送订阅..."
PUSH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"push_subscription\": {
      \"push_token\": \"test_fcm_token_$(date +%s)\",
      \"device_id\": \"test_device_$(date +%s)\",
      \"platform\": \"android\"
    }
  }")

HTTP_CODE=$(echo "$PUSH_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$PUSH_RESPONSE" | sed '/HTTP_CODE:/d')

echo "HTTP 状态码: $HTTP_CODE"
echo "响应body: $BODY"
echo ""

if [ "$HTTP_CODE" == "201" ]; then
  echo "✅ 推送订阅注册成功！"
  echo ""
  echo "🎉 测试完成！现在可以："
  echo "  1. 在 Chatwoot 后台发送消息"
  echo "  2. 检查 Flutter 应用是否收到推送通知"
else
  echo "❌ 推送订阅注册失败"
  echo "HTTP Code: $HTTP_CODE"
fi

echo ""
echo "💡 提示: 查看数据库中的订阅记录:"
echo "docker-compose -f docker-compose.development.yaml exec postgres psql -U postgres -d chatwoot -c 'SELECT * FROM contact_push_subscriptions;'"
