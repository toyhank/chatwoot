#!/bin/bash

# 账号注销接口测试脚本
# 使用方法: ./test_delete_account.sh [base_url]
# 例如: ./test_delete_account.sh http://localhost:3000

BASE_URL="${1:-http://localhost:3000}"
API_BASE="$BASE_URL/api/mobile"

echo "================================================"
echo "  账号注销接口测试脚本"
echo "  Base URL: $BASE_URL"
echo "================================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 生成随机邮箱
TIMESTAMP=$(date +%s)
TEST_EMAIL="test_delete_${TIMESTAMP}@example.com"
TEST_PASSWORD="test123456"
TEST_NICKNAME="测试用户${TIMESTAMP}"

echo "${YELLOW}步骤 1: 注册测试账户${NC}"
echo "邮箱: $TEST_EMAIL"
echo "密码: $TEST_PASSWORD"
echo ""

# 1. 发送验证码
echo "1.1 发送验证码..."
SEND_CODE_RESPONSE=$(curl -s -X POST "$API_BASE/register/send_code" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\"}")

echo "响应: $SEND_CODE_RESPONSE"

# 从数据库获取验证码（需要 Rails console）
echo ""
echo "${YELLOW}请在另一个终端执行以下命令获取验证码:${NC}"
echo "cd /home/chatwoot1/chatwoot"
echo "bin/rails runner \"puts EmailVerificationCode.where(email: '$TEST_EMAIL').last.code\""
echo ""
read -p "请输入验证码: " VERIFICATION_CODE

# 2. 注册用户
echo ""
echo "1.2 注册用户..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/register/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":\"$TEST_EMAIL\",
    \"code\":\"$VERIFICATION_CODE\",
    \"password\":\"$TEST_PASSWORD\",
    \"nickname\":\"$TEST_NICKNAME\"
  }")

echo "响应: $REGISTER_RESPONSE"

# 提取 uid
USER_ID=$(echo $REGISTER_RESPONSE | grep -o '"uid":[0-9]*' | grep -o '[0-9]*')

if [ -z "$USER_ID" ]; then
  echo "${RED}✗ 注册失败，无法继续测试${NC}"
  exit 1
fi

echo "${GREEN}✓ 注册成功，用户ID: $USER_ID${NC}"

# 3. 登录获取 access_token
echo ""
echo "${YELLOW}步骤 2: 登录账户${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/register/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":\"$TEST_EMAIL\",
    \"password\":\"$TEST_PASSWORD\"
  }")

echo "响应: $LOGIN_RESPONSE"

# 4. 从数据库获取 Bearer token
echo ""
echo "${YELLOW}步骤 3: 获取 Bearer Token${NC}"
echo "请在另一个终端执行以下命令获取 Bearer token:"
echo "cd /home/chatwoot1/chatwoot"
echo "bin/rails runner \"puts User.find($USER_ID).access_token.token\""
echo ""
read -p "请输入 Bearer token: " BEARER_TOKEN

# 5. 测试删除账户
echo ""
echo "${YELLOW}步骤 4: 测试删除账户接口${NC}"
echo "调用 DELETE $API_BASE/user/delete"
echo "Authorization: Bearer $BEARER_TOKEN"
echo ""

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json")

# 分离响应体和状态码
HTTP_BODY=$(echo "$DELETE_RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $HTTP_CODE"
echo "响应体: $HTTP_BODY"

if [ "$HTTP_CODE" = "200" ]; then
  echo "${GREEN}✓ 删除成功！${NC}"
else
  echo "${RED}✗ 删除失败！${NC}"
fi

# 6. 验证删除效果 - 尝试再次登录
echo ""
echo "${YELLOW}步骤 5: 验证删除效果（尝试再次登录）${NC}"
VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/register/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":\"$TEST_EMAIL\",
    \"password\":\"$TEST_PASSWORD\"
  }")

VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | head -n -1)
VERIFY_CODE=$(echo "$VERIFY_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $VERIFY_CODE"
echo "响应体: $VERIFY_BODY"

if [ "$VERIFY_CODE" = "400" ] || echo "$VERIFY_BODY" | grep -q "邮箱或密码错误"; then
  echo "${GREEN}✓ 验证成功：用户已被删除，无法登录${NC}"
else
  echo "${RED}✗ 验证失败：用户可能未被完全删除${NC}"
fi

# 7. 测试无效 token
echo ""
echo "${YELLOW}步骤 6: 测试无效 Bearer Token${NC}"
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer invalid_token_12345" \
  -H "Content-Type: application/json")

INVALID_BODY=$(echo "$INVALID_RESPONSE" | head -n -1)
INVALID_CODE=$(echo "$INVALID_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $INVALID_CODE"
echo "响应体: $INVALID_BODY"

if [ "$INVALID_CODE" = "401" ]; then
  echo "${GREEN}✓ 测试通过：无效 token 返回 401${NC}"
else
  echo "${RED}✗ 测试失败：应返回 401${NC}"
fi

# 8. 测试缺失 Authorization header
echo ""
echo "${YELLOW}步骤 7: 测试缺失 Authorization Header${NC}"
NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Content-Type: application/json")

NO_AUTH_BODY=$(echo "$NO_AUTH_RESPONSE" | head -n -1)
NO_AUTH_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $NO_AUTH_CODE"
echo "响应体: $NO_AUTH_BODY"

if [ "$NO_AUTH_CODE" = "401" ]; then
  echo "${GREEN}✓ 测试通过：缺失 header 返回 401${NC}"
else
  echo "${RED}✗ 测试失败：应返回 401${NC}"
fi

# 总结
echo ""
echo "================================================"
echo "  测试完成"
echo "================================================"
echo ""
echo "测试摘要:"
echo "- 创建测试用户: $TEST_EMAIL"
echo "- 删除账户测试: $([ "$HTTP_CODE" = "200" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "- 删除验证测试: $([ "$VERIFY_CODE" = "400" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "- 无效token测试: $([ "$INVALID_CODE" = "401" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "- 缺失header测试: $([ "$NO_AUTH_CODE" = "401" ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo ""
