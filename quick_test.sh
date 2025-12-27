#!/bin/bash
# 快速测试脚本

BASE_URL="http://localhost:8080/api/mobile/register"
EMAIL="test$(date +%s)@example.com"

echo "=== 1. 检查邮箱 ==="
curl -s "${BASE_URL}/check_email?email=${EMAIL}" | python3 -m json.tool
echo ""

echo "=== 2. 发送验证码 ==="
curl -s -X POST "${BASE_URL}/send_code" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${EMAIL}\"}" | python3 -m json.tool
echo ""

echo "=== 获取验证码（从数据库）==="
CODE=$(docker-compose -f docker-compose.development.yaml exec -T rails bundle exec rails runner "
code = EmailVerificationCode.where(email: '${EMAIL}').order(created_at: :desc).first
puts code.code if code
" 2>/dev/null | tail -1)
echo "验证码: ${CODE}"
echo ""

if [ -n "$CODE" ]; then
  echo "=== 3. 用户注册 ==="
  curl -s -X POST "${BASE_URL}/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${EMAIL}\", \"code\": \"${CODE}\", \"password\": \"password123\", \"nickname\": \"测试用户\"}" | python3 -m json.tool
  echo ""
  
  echo "=== 4. 用户登录 ==="
  curl -s -X POST "${BASE_URL}/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${EMAIL}\", \"password\": \"password123\"}" | python3 -m json.tool
fi
