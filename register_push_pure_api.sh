#!/bin/bash

# ==========================================
# 纯API方式注册推送订阅脚本
# 基于 Widget推送API使用说明-更新版.md
# ==========================================

# 默认配置
BASE_URL="http://localhost:8080"
WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"

# 参数检查
if [ $# -lt 2 ]; then
  echo "Usage: $0 <email> <fcm_token> [name]"
  echo "Example: $0 test@example.com fcm_token_123 'Test User'"
  exit 1
fi

EMAIL=$1
FCM_TOKEN=$2
NAME=${3:-$EMAIL}
DEVICE_ID="script_api_$(date +%s)"

echo "----------------------------------------"
echo "🚀 开始注册推送 (纯API模式)"
echo "----------------------------------------"
echo "📧 Email: $EMAIL"
echo "🔑 FCM Token: ${FCM_TOKEN:0:20}..."
echo "🌐 Base URL: $BASE_URL"
echo "----------------------------------------"

# 1. 初始化 Widget 并获取 Auth Token
echo "step 1: 初始化 Widget (POST /config)..."

RESPONSE_BODY=$(mktemp)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$RESPONSE_BODY" \
  -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\"
  }")

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "❌ 初始化失败! HTTP Code: $HTTP_CODE"
  cat "$RESPONSE_BODY"
  rm "$RESPONSE_BODY"
  exit 1
fi

# 提取 Auth Token (从 JSON 响应)
# 响应结构: {"website_channel_config": {"auth_token": "..."}}
AUTH_TOKEN=$(grep -o '"auth_token":"[^"]*"' "$RESPONSE_BODY" | awk -F'"' '{print $4}')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ 无法从响应获取 Auth Token"
  cat "$RESPONSE_BODY"
  rm "$RESPONSE_BODY"
  exit 1
fi

echo "✅ 获取 Token 成功: ${AUTH_TOKEN:0:20}..."
rm "$RESPONSE_BODY"

# 2. 更新 Contact 信息 (合并联系人)
echo -e "\nStep 2: 更新联系人信息 (PATCH /contact)..."

UPDATE_RESPONSE=$(curl -s -w "\\nHTTP_CODE:%{http_code}" \
  -X PATCH "$BASE_URL/api/v1/widget/contact" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"identifier\": \"$EMAIL\",
    \"email\": \"$EMAIL\",
    \"name\": \"$NAME\"
  }")

UPDATE_HTTP_CODE=$(echo "$UPDATE_RESPONSE" | grep "HTTP_CODE" | awk -F: '{print $2}')
if [ "$UPDATE_HTTP_CODE" -ne 200 ]; then
  echo "⚠️ 更新联系人失败 (可能不影响推送注册), HTTP: $UPDATE_HTTP_CODE"
  # 不退出，尝试继续注册
else
  echo "✅ 联系人信息已更新"
fi

# 3. 注册推送订阅
echo -e "\nStep 3: 注册推送订阅..."

PUSH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"push_subscription\": {
      \"push_token\": \"$FCM_TOKEN\",
      \"device_id\": \"$DEVICE_ID\",
      \"platform\": \"android\"
    }
  }")

PUSH_HTTP_CODE=$(echo "$PUSH_RESPONSE" | grep "HTTP_CODE" | awk -F: '{print $2}')
PUSH_BODY=$(echo "$PUSH_RESPONSE" | head -n 1)

if [ "$PUSH_HTTP_CODE" -eq 201 ] || [ "$PUSH_HTTP_CODE" -eq 200 ]; then
  echo "✅ 注册成功!"
  echo "Response: $PUSH_BODY"
else
  echo "❌ 注册失败! HTTP Code: $PUSH_HTTP_CODE"
  echo "Response: $PUSH_BODY"
  exit 1
fi

echo "----------------------------------------"
echo "🎉 完成!"
