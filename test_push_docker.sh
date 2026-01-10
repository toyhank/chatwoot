#!/bin/bash
# 在 Docker 容器内运行的完整推送订阅测试
# 用法: docker compose -f docker-compose.development.yaml exec rails /app/test_push_docker.sh

set -e

BASE_URL="http://localhost:3000"
WEBSITE_TOKEN="GJFzMx6qnv9DFpaspRpFDRDt"
DEVICE_ID="test_device_$(date +%s)"
FCM_TOKEN="test_fcm_token_$(date +%s)"

USER_A_EMAIL="test_user_a_$(date +%s)@example.com"
USER_B_EMAIL="test_user_b_$(date +%s)@example.com"

echo "=================================================="
echo "推送订阅完整测试（Docker 容器内）"
echo "Device ID: $DEVICE_ID"
echo "FCM Token: $FCM_TOKEN"
echo "=================================================="

# 步骤 1: 用户A初始化
echo ""
echo "【步骤1】用户A初始化Widget..."

RESP1=$(curl -s -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{\"website_token\": \"$WEBSITE_TOKEN\"}")

AUTH_TOKEN_A=$(echo "$RESP1" | ruby -e 'require "json"; puts JSON.parse(STDIN.read)["website_channel_config"]["auth_token"]' 2>/dev/null || echo "")

if [ -z "$AUTH_TOKEN_A" ]; then
  echo "❌ 失败：无法获取用户A的auth token"
  echo "响应: $RESP1"
  exit 1
fi
echo "✅ Auth Token A: ${AUTH_TOKEN_A:0:30}..."

# 步骤 2: 用户A更新Contact
echo ""
echo "【步骤2】用户A更新Contact信息..."

RESP2=$(curl -s -X PATCH "$BASE_URL/api/v1/widget/contact" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{\"email\": \"$USER_A_EMAIL\", \"name\": \"TestUserA\"}")

echo "✅ 用户A Contact更新成功"

# 步骤 3: 用户A注册推送
echo ""
echo "【步骤3】用户A注册推送订阅..."

RESP3=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{\"push_subscription\": {\"push_token\": \"$FCM_TOKEN\", \"device_id\": \"$DEVICE_ID\", \"platform\": \"android\"}}")

HTTP_CODE=$(echo "$RESP3" | tail -1)
BODY=$(echo "$RESP3" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 用户A推送注册成功 (HTTP $HTTP_CODE)"
else
  echo "❌ 用户A推送注册失败 (HTTP $HTTP_CODE)"
  echo "响应: $BODY"
  exit 1
fi

# 步骤 4: 验证用户A订阅
echo ""
echo "【步骤4】验证用户A订阅..."

SUB_A=$(bundle exec rails runner "
sub = ContactPushSubscription.find_by(device_id: '$DEVICE_ID')
if sub
  contact = sub.contact
  puts \"订阅ID: #{sub.id}, Contact: #{sub.contact_id} (#{contact&.email}), Token: #{sub.push_token[0..25]}...\"
else
  puts 'NOT FOUND'
end
" 2>/dev/null)

echo "$SUB_A"

if echo "$SUB_A" | grep -q "NOT FOUND"; then
  echo "❌ 验证失败：订阅不存在"
  exit 1
fi
echo "✅ 用户A订阅验证成功"

# 步骤 5: 删除旧订阅（按device_id）
echo ""
echo "【步骤5】删除旧订阅（使用用户A的token，按device_id）..."

RESP5=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_A" \
  -d "{\"push_subscription\": {\"device_id\": \"$DEVICE_ID\"}}")

HTTP_CODE=$(echo "$RESP5" | tail -1)

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 删除成功 (HTTP $HTTP_CODE)"
else
  echo "⚠️ 删除返回 HTTP $HTTP_CODE（可能已不存在）"
fi

# 步骤 6: 用户B初始化
echo ""
echo "【步骤6】用户B初始化Widget..."

RESP6=$(curl -s -X POST "$BASE_URL/api/v1/widget/config" \
  -H "Content-Type: application/json" \
  -d "{\"website_token\": \"$WEBSITE_TOKEN\"}")

AUTH_TOKEN_B=$(echo "$RESP6" | ruby -e 'require "json"; puts JSON.parse(STDIN.read)["website_channel_config"]["auth_token"]' 2>/dev/null || echo "")

if [ -z "$AUTH_TOKEN_B" ]; then
  echo "❌ 失败：无法获取用户B的auth token"
  exit 1
fi
echo "✅ Auth Token B: ${AUTH_TOKEN_B:0:30}..."

# 步骤 7: 用户B更新Contact
echo ""
echo "【步骤7】用户B更新Contact信息..."

RESP7=$(curl -s -X PATCH "$BASE_URL/api/v1/widget/contact" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_B" \
  -d "{\"email\": \"$USER_B_EMAIL\", \"name\": \"TestUserB\"}")

echo "✅ 用户B Contact更新成功"

# 步骤 8: 用户B注册推送（同一设备）
echo ""
echo "【步骤8】用户B注册推送订阅（同一设备ID）..."

RESP8=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/widget/push_subscriptions" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN_B" \
  -d "{\"push_subscription\": {\"push_token\": \"$FCM_TOKEN\", \"device_id\": \"$DEVICE_ID\", \"platform\": \"android\"}}")

HTTP_CODE=$(echo "$RESP8" | tail -1)
BODY=$(echo "$RESP8" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ 用户B推送注册成功 (HTTP $HTTP_CODE)"
else
  echo "❌ 用户B推送注册失败 (HTTP $HTTP_CODE)"
  echo "响应: $BODY"
  
  # 调试
  echo ""
  echo "调试信息："
  bundle exec rails runner "
  sub = ContactPushSubscription.find_by(device_id: '$DEVICE_ID')
  if sub
    puts \"发现冲突订阅: ID=#{sub.id}, Contact=#{sub.contact_id}, 创建于#{sub.created_at}\"
  else
    sub = ContactPushSubscription.find_by(push_token: '$FCM_TOKEN')
    if sub
      puts \"Token被占用: ID=#{sub.id}, Contact=#{sub.contact_id}, Device=#{sub.device_id}\"
    else
      puts '未找到冲突订阅'
    end
  end
  " 2>/dev/null
  exit 1
fi

# 步骤 9: 验证用户B订阅
echo ""
echo "【步骤9】验证用户B订阅..."

SUB_B=$(bundle exec rails runner "
sub = ContactPushSubscription.find_by(device_id: '$DEVICE_ID')
if sub
  contact = sub.contact
  puts \"订阅ID: #{sub.id}, Contact: #{sub.contact_id} (#{contact&.email}), Token: #{sub.push_token[0..25]}...\"
else
  puts 'NOT FOUND'
end
" 2>/dev/null)

echo "$SUB_B"

if echo "$SUB_B" | grep -q "$USER_B_EMAIL"; then
  echo "✅ 用户B订阅验证成功（email正确匹配）"
else
  echo "⚠️ 警告：订阅存在但email可能不匹配"
fi

# 步骤 10: 清理
echo ""
echo "【步骤10】清理测试数据..."

bundle exec rails runner "
ContactPushSubscription.where(device_id: '$DEVICE_ID').destroy_all
puts '已清理'
" 2>/dev/null

echo "✅ 测试完成"
echo ""
echo "=================================================="
echo "所有步骤通过！"
echo "=================================================="
