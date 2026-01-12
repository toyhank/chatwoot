#!/bin/bash
# 在 Docker 容器内测试推送订阅注册

BASE_URL="http://rails:3000"
WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"
FCM_TOKEN="fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ"
DEVICE_ID=$(date +%s)

echo "================================================================================"
echo "推送订阅注册测试"
echo "================================================================================"

# 步骤1: 设置用户身份
echo ""
echo "步骤1: 设置用户身份为 yushuangqi@hotmail.com"
echo "--------------------------------------------------------------------------------"

SET_USER_RESPONSE=$(curl -s -X PATCH "${BASE_URL}/api/v1/widget/contact/set_user" \
  -H "Content-Type: application/json" \
  -d "{\"website_token\":\"${WEBSITE_TOKEN}\",\"identifier\":\"yushuangqi@hotmail.com\",\"name\":\"toy\"}")

echo "响应: $SET_USER_RESPONSE"

# 提取 pubsub_token (使用更简单的方法)
AUTH_TOKEN=$(echo "$SET_USER_RESPONSE" | sed -n 's/.*"pubsub_token":"\([^"]*\)".*/\1/p')
SOURCE_ID=$(echo "$SET_USER_RESPONSE" | sed -n 's/.*"source_id":"\([^"]*\)".*/\1/p')
CONTACT_ID=$(echo "$SET_USER_RESPONSE" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')

if [ -z "$AUTH_TOKEN" ]; then
  echo "✗ 未能获取 Auth Token"
  exit 1
fi

echo ""
echo "✓ 获取到 Auth Token: $AUTH_TOKEN"
echo "✓ Source ID: $SOURCE_ID"
echo "✓ Contact ID: $CONTACT_ID"

# 步骤2: 注册推送订阅
echo ""
echo "================================================================================"
echo "步骤2: 使用正确的 Auth Token 注册推送订阅"
echo "--------------------------------------------------------------------------------"
echo "请求URL: ${BASE_URL}/api/v1/widget/push_subscriptions"
echo "Auth Token: ${AUTH_TOKEN}"
echo "Device ID: ${DEVICE_ID}"

PUSH_SUB_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${BASE_URL}/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: ${AUTH_TOKEN}" \
  -d "{\"website_token\":\"${WEBSITE_TOKEN}\",\"push_subscription\":{\"push_token\":\"${FCM_TOKEN}\",\"device_id\":\"${DEVICE_ID}\",\"platform\":\"android\"}}")

HTTP_CODE=$(echo "$PUSH_SUB_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$PUSH_SUB_RESPONSE" | sed 's/HTTP_CODE:[0-9]*//')

echo ""
echo "HTTP 状态码: $HTTP_CODE"
echo "响应Body: $RESPONSE_BODY"

# 检查是否成功
if [ "$HTTP_CODE" = "201" ]; then
  SUBSCRIPTION_ID=$(echo "$RESPONSE_BODY" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
  SUB_CONTACT_ID=$(echo "$RESPONSE_BODY" | sed -n 's/.*"contact_id":\([0-9]*\).*/\1/p')
  CONTACT_INBOX_ID=$(echo "$RESPONSE_BODY" | sed -n 's/.*"contact_inbox_id":\([0-9]*\).*/\1/p')
  
  echo ""
  echo "✓ 推送订阅注册成功!"
  echo "  - 订阅ID: $SUBSCRIPTION_ID"
  echo "  - 联系人ID: $SUB_CONTACT_ID"
  echo "  - Contact Inbox ID: $CONTACT_INBOX_ID"
  
  # 验证数据库
  echo ""
  echo "================================================================================"
  echo "步骤3: 验证数据库中的订阅"
  echo "--------------------------------------------------------------------------------"
else
  echo ""
  echo "✗ 推送订阅注册失败 (HTTP $HTTP_CODE)"
fi

echo ""
echo "================================================================================"
echo "测试完成"
echo "================================================================================"
