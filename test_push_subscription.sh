#!/bin/bash
# 使用 curl 测试推送订阅注册

set -e

BASE_URL="http://localhost:3000"
WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"
FCM_TOKEN="fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ"
DEVICE_ID=$(date +%s)

echo "================================================================================"
echo "推送订阅注册测试 - 使用 curl"
echo "================================================================================"

# 步骤1: 设置用户身份
echo ""
echo "步骤1: 设置用户身份为 yushuangqi@hotmail.com"
echo "--------------------------------------------------------------------------------"

SET_USER_RESPONSE=$(curl -s -X PATCH "${BASE_URL}/api/v1/widget/contact/set_user" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"${WEBSITE_TOKEN}\",
    \"identifier\": \"yushuangqi@hotmail.com\",
    \"name\": \"toy\"
  }")

echo "响应: $SET_USER_RESPONSE"

# 提取 pubsub_token
AUTH_TOKEN=$(echo $SET_USER_RESPONSE | grep -o '"pubsub_token":"[^"]*"' | cut -d'"' -f4)
SOURCE_ID=$(echo $SET_USER_RESPONSE | grep -o '"source_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
  echo "✗ 未能获取 Auth Token"
  exit 1
fi

echo ""
echo "✓ 获取到 Auth Token: $AUTH_TOKEN"
echo "✓ Source ID: $SOURCE_ID"

# 步骤2: 注册推送订阅
echo ""
echo "================================================================================"
echo "步骤2: 使用正确的 Auth Token 注册推送订阅"
echo "--------------------------------------------------------------------------------"

PUSH_SUB_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: ${AUTH_TOKEN}" \
  -d "{
    \"website_token\": \"${WEBSITE_TOKEN}\",
    \"push_subscription\": {
      \"push_token\": \"${FCM_TOKEN}\",
      \"device_id\": \"${DEVICE_ID}\",
      \"platform\": \"android\"
    }
  }")

echo "响应: $PUSH_SUB_RESPONSE"

# 检查是否成功
if echo "$PUSH_SUB_RESPONSE" | grep -q '"id"'; then
  SUBSCRIPTION_ID=$(echo $PUSH_SUB_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
  CONTACT_ID=$(echo $PUSH_SUB_RESPONSE | grep -o '"contact_id":[0-9]*' | cut -d':' -f2)
  CONTACT_INBOX_ID=$(echo $PUSH_SUB_RESPONSE | grep -o '"contact_inbox_id":[0-9]*' | cut -d':' -f2)
  
  echo ""
  echo "✓ 推送订阅注册成功!"
  echo "  - 订阅ID: $SUBSCRIPTION_ID"
  echo "  - 联系人ID: $CONTACT_ID"
  echo "  - Contact Inbox ID: $CONTACT_INBOX_ID"
else
  echo ""
  echo "✗ 推送订阅注册失败"
fi

echo ""
echo "================================================================================"
echo "测试完成"
echo "================================================================================"
