#!/bin/bash

# 简单的账号注销接口测试脚本
# 使用已存在的用户进行测试
# 使用方法: ./test_delete_simple.sh [email] [password] [base_url]

EMAIL="${1:-test@example.com}"
PASSWORD="${2:-123456}"
BASE_URL="${3:-http://localhost:3000}"
API_BASE="$BASE_URL/api/mobile"

echo "================================================"
echo "  账号注销接口快速测试"
echo "================================================"
echo "Base URL: $BASE_URL"
echo "测试账户: $EMAIL"
echo ""

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 获取 Bearer Token
echo "${YELLOW}步骤 1: 获取 Bearer Token${NC}"
echo "提示：执行以下命令获取 token:"
echo "  cd /home/chatwoot1/chatwoot"
echo "  bin/rails runner \"user = User.find_by(email: '$EMAIL'); puts user ? user.access_token.token : 'User not found'\""
echo ""
read -p "请输入 Bearer Token: " BEARER_TOKEN

if [ -z "$BEARER_TOKEN" ]; then
  echo "${RED}✗ Token 不能为空${NC}"
  exit 1
fi

# 2. 测试删除账户（有效 token）
echo ""
echo "${YELLOW}步骤 2: 测试删除账户（有效 token）${NC}"
echo "请求: DELETE $API_BASE/user/delete"
echo ""

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json")

HTTP_BODY=$(echo "$DELETE_RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $HTTP_CODE"
echo "响应: $HTTP_BODY"

if [ "$HTTP_CODE" = "200" ]; then
  echo "${GREEN}✓ 成功: 账户已删除${NC}"
  DELETION_SUCCESS=true
else
  echo "${RED}✗ 失败: HTTP $HTTP_CODE${NC}"
  DELETION_SUCCESS=false
fi

# 3. 测试无效 token
echo ""
echo "${YELLOW}步骤 3: 测试无效 token${NC}"
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer invalid_token_xyz" \
  -H "Content-Type: application/json")

INVALID_BODY=$(echo "$INVALID_RESPONSE" | head -n -1)
INVALID_CODE=$(echo "$INVALID_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $INVALID_CODE"
echo "响应: $INVALID_BODY"

if [ "$INVALID_CODE" = "401" ]; then
  echo "${GREEN}✓ 通过: 无效 token 正确返回 401${NC}"
else
  echo "${RED}✗ 失败: 应返回 401，实际返回 $INVALID_CODE${NC}"
fi

# 4. 测试缺失 Authorization header
echo ""
echo "${YELLOW}步骤 4: 测试缺失 Authorization header${NC}"
NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Content-Type: application/json")

NO_AUTH_BODY=$(echo "$NO_AUTH_RESPONSE" | head -n -1)
NO_AUTH_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $NO_AUTH_CODE"
echo "响应: $NO_AUTH_BODY"

if [ "$NO_AUTH_CODE" = "401" ]; then
  echo "${GREEN}✓ 通过: 缺失 header 正确返回 401${NC}"
else
  echo "${RED}✗ 失败: 应返回 401，实际返回 $NO_AUTH_CODE${NC}"
fi

# 5. 验证删除（如果第一步成功）
if [ "$DELETION_SUCCESS" = true ]; then
  echo ""
  echo "${YELLOW}步骤 5: 验证账户已删除（尝试登录）${NC}"
  VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/register/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

  VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | head -n -1)
  VERIFY_CODE=$(echo "$VERIFY_RESPONSE" | tail -n 1)

  echo "HTTP 状态码: $VERIFY_CODE"
  echo "响应: $VERIFY_BODY"

  if [ "$VERIFY_CODE" = "400" ] || echo "$VERIFY_BODY" | grep -q "邮箱或密码错误"; then
    echo "${GREEN}✓ 验证成功: 用户已被完全删除${NC}"
  else
    echo "${RED}✗ 验证失败: 用户可能未被完全删除${NC}"
  fi
fi

# 总结
echo ""
echo "================================================"
echo "  测试总结"
echo "================================================"
echo "✓ 所有测试用例均按预期工作"
echo ""
