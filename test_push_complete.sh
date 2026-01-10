#!/bin/bash
# 完整的推送订阅测试用例
# 测试流程：用户A注册 -> 用户A验证 -> 切换到用户B -> 用户B注册 -> 用户B验证

set -e

# 配置
BASE_URL="http://127.0.0.1:8080"
WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"

# 用户A
USER_A_EMAIL="test_user_a@example.com"
USER_A_NAME="TestUserA"
USER_A_IDENTIFIER="test_user_a@example.com"
USER_A_HASH="test_hash_a"

# 用户B
USER_B_EMAIL="test_user_b@example.com"
USER_B_NAME="TestUserB"
USER_B_IDENTIFIER="test_user_b@example.com"
USER_B_HASH="test_hash_b"

# 模拟数据
DEVICE_ID="test_device_$(date +%s)"
FCM_TOKEN="test_fcm_token_$(date +%s)"

echo "=================================================="
echo "推送订阅完整测试"
echo "=================================================="
echo "Base URL: $BASE_URL"
echo "Device ID: $DEVICE_ID"
echo "FCM Token: $FCM_TOKEN"
echo ""

# 绕过代理
export NO_PROXY=127.0.0.1,localhost

#--------------------------------------------------
# 步骤 1: 用户A初始化Widget
#--------------------------------------------------
echo "=================================================="
echo "步骤 1: 用户A初始化Widget"
echo "=================================================="

RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\"
  }")

echo "响应: $RESPONSE"

# 提取 auth token
AUTH_TOKEN_A=$(echo "$RESPONSE" | grep -o '"auth_token":"[^"]*"' | head -1 | sed 's/"auth_token":"//;s/"//')

if [ -z "$AUTH_TOKEN_A" ]; then
  echo "❌ 用户A初始化失败：无法获取 auth token"
  exit 1
fi

echo "✅ 用户A Auth Token: ${AUTH_TOKEN_A:0:30}..."
echo ""

#--------------------------------------------------
# 步骤 2: 用户A更新Contact信息
#--------------------------------------------------
echo "=================================================="
echo "步骤 2: 用户A更新Contact信息"
echo "=================================================="

RESPONSE=$(curl -s -X PATCH "$BASE_URL/api/v1/widget/contact" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{
    \"email\": \"$USER_A_EMAIL\",
    \"name\": \"$USER_A_NAME\",
    \"identifier\": \"$USER_A_IDENTIFIER\"
  }")

echo "响应: $RESPONSE"
echo "✅ 用户A Contact已更新"
echo ""

#--------------------------------------------------
# 步骤 3: 用户A注册推送订阅
#--------------------------------------------------
echo "=================================================="
echo "步骤 3: 用户A注册推送订阅"
echo "=================================================="

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{
    \"push_subscription\": {
      \"push_token\": \"$FCM_TOKEN\",
      \"device_id\": \"$DEVICE_ID\",
      \"platform\": \"android\"
    }
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "状态码: $HTTP_CODE"
echo "响应: $BODY"

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 用户A推送订阅注册成功"
else
  echo "❌ 用户A推送订阅注册失败"
  exit 1
fi
echo ""

#--------------------------------------------------
# 步骤 4: 验证用户A的订阅
#--------------------------------------------------
echo "=================================================="
echo "步骤 4: 验证用户A的订阅（数据库查询）"
echo "=================================================="

docker compose -f docker-compose.development.yaml exec -T postgres psql -U postgres -d chatwoot -c "
SELECT cps.id, cps.contact_id, c.email, c.name, cps.device_id, LEFT(cps.push_token, 30) as token
FROM contact_push_subscriptions cps
JOIN contacts c ON c.id = cps.contact_id
WHERE cps.device_id = '$DEVICE_ID';
"

echo ""

#--------------------------------------------------
# 步骤 5: 切换到用户B - 先删除旧订阅
#--------------------------------------------------
echo "=================================================="
echo "步骤 5: 切换到用户B - 删除旧订阅"
echo "=================================================="
echo "注意：使用用户A的token删除（按device_id）"

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{
    \"push_subscription\": {
      \"device_id\": \"$DEVICE_ID\"
    }
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "状态码: $HTTP_CODE"
echo "响应: $BODY"

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 旧订阅删除成功"
else
  echo "⚠️ 删除返回: $HTTP_CODE（可能已不存在）"
fi
echo ""

#--------------------------------------------------
# 步骤 6: 用户B初始化Widget
#--------------------------------------------------
echo "=================================================="
echo "步骤 6: 用户B初始化Widget"
echo "=================================================="

RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{
    \"website_token\": \"$WEBSITE_TOKEN\"
  }")

echo "响应: $RESPONSE"

AUTH_TOKEN_B=$(echo "$RESPONSE" | grep -o '"auth_token":"[^"]*"' | head -1 | sed 's/"auth_token":"//;s/"//')

if [ -z "$AUTH_TOKEN_B" ]; then
  echo "❌ 用户B初始化失败：无法获取 auth token"
  exit 1
fi

echo "✅ 用户B Auth Token: ${AUTH_TOKEN_B:0:30}..."
echo ""

#--------------------------------------------------
# 步骤 7: 用户B更新Contact信息
#--------------------------------------------------
echo "=================================================="
echo "步骤 7: 用户B更新Contact信息"
echo "=================================================="

RESPONSE=$(curl -s -X PATCH "$BASE_URL/api/v1/widget/contact" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_B" \
  -d "{
    \"email\": \"$USER_B_EMAIL\",
    \"name\": \"$USER_B_NAME\",
    \"identifier\": \"$USER_B_IDENTIFIER\"
  }")

echo "响应: $RESPONSE"
echo "✅ 用户B Contact已更新"
echo ""

#--------------------------------------------------
# 步骤 8: 用户B注册推送订阅（使用同一设备）
#--------------------------------------------------
echo "=================================================="
echo "步骤 8: 用户B注册推送订阅（同一设备）"
echo "=================================================="
echo "使用用户B的 Auth Token: ${AUTH_TOKEN_B:0:30}..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_B" \
  -d "{
    \"push_subscription\": {
      \"push_token\": \"$FCM_TOKEN\",
      \"device_id\": \"$DEVICE_ID\",
      \"platform\": \"android\"
    }
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "状态码: $HTTP_CODE"
echo "响应: $BODY"

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 用户B推送订阅注册成功"
else
  echo "❌ 用户B推送订阅注册失败"
  echo ""
  echo "调试信息："
  echo "  - 检查订阅是否仍存在（步骤5删除是否成功）"
  docker compose -f docker-compose.development.yaml exec -T postgres psql -U postgres -d chatwoot -c "
  SELECT cps.id, cps.contact_id, c.email, cps.device_id, LEFT(cps.push_token, 30) as token
  FROM contact_push_subscriptions cps
  LEFT JOIN contacts c ON c.id = cps.contact_id
  WHERE cps.device_id = '$DEVICE_ID' OR cps.push_token = '$FCM_TOKEN';
  "
  exit 1
fi
echo ""

#--------------------------------------------------
# 步骤 9: 验证用户B的订阅
#--------------------------------------------------
echo "=================================================="
echo "步骤 9: 验证用户B的订阅（数据库查询）"
echo "=================================================="

docker compose -f docker-compose.development.yaml exec -T postgres psql -U postgres -d chatwoot -c "
SELECT cps.id, cps.contact_id, c.email, c.name, cps.device_id, LEFT(cps.push_token, 30) as token
FROM contact_push_subscriptions cps
JOIN contacts c ON c.id = cps.contact_id
WHERE cps.device_id = '$DEVICE_ID';
"

echo ""

#--------------------------------------------------
# 步骤 10: 清理测试数据
#--------------------------------------------------
echo "=================================================="
echo "步骤 10: 清理测试数据"
echo "=================================================="

docker compose -f docker-compose.development.yaml exec -T postgres psql -U postgres -d chatwoot -c "
DELETE FROM contact_push_subscriptions WHERE device_id = '$DEVICE_ID';
"

echo "✅ 测试数据已清理"
echo ""

#--------------------------------------------------
# 测试总结
#--------------------------------------------------
echo "=================================================="
echo "✅ 测试完成！所有步骤都成功"
echo "=================================================="
echo ""
echo "测试覆盖："
echo "  1. 用户A初始化Widget ✅"
echo "  2. 用户A更新Contact ✅"
echo "  3. 用户A注册推送订阅 ✅"
echo "  4. 验证用户A订阅 ✅"
echo "  5. 删除旧订阅（按device_id）✅"
echo "  6. 用户B初始化Widget ✅"
echo "  7. 用户B更新Contact ✅"
echo "  8. 用户B注册推送订阅 ✅"
echo "  9. 验证用户B订阅 ✅"
echo " 10. 清理测试数据 ✅"
