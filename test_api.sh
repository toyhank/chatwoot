#!/bin/sh
# 测试推送订阅API注册

WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"
AUTH_TOKEN="2GKtPjYfYgKe9iXV3vUvvtGt"
FCM_TOKEN="fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ"
DEVICE_ID="test_$(date +%s)"

echo "Testing Push Subscription API"
echo "=============================="
echo "Website Token: $WEBSITE_TOKEN"
echo "Auth Token: $AUTH_TOKEN"
echo "Device ID: $DEVICE_ID"
echo ""

curl -v -X POST "http://localhost:3000/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\",
    \"push_subscription\": {
      \"push_token\": \"$FCM_TOKEN\",
      \"device_id\": \"$DEVICE_ID\",
      \"platform\": \"android\"
    }
  }"

echo ""
echo "=============================="
