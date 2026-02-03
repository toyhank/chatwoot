#!/bin/bash

# 生产环境账号注销接口测试脚本
# 使用方法: ./test_production.sh [production_url] [test_email] [test_password]

PROD_URL="${1}"
TEST_EMAIL="${2}"
TEST_PASSWORD="${3}"

if [ -z "$PROD_URL" ]; then
  echo "错误: 请提供生产环境 URL"
  echo "用法: $0 <production_url> [test_email] [test_password]"
  echo "示例: $0 https://your-domain.com test@example.com password123"
  exit 1
fi

# 移除末尾的斜杠
PROD_URL="${PROD_URL%/}"
API_BASE="$PROD_URL/api/mobile"

echo "================================================"
echo "  生产环境账号注销接口测试"
echo "================================================"
echo "环境 URL: $PROD_URL"
echo ""

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 步骤 1: 获取 Bearer Token
echo "${YELLOW}步骤 1: 获取 Bearer Token${NC}"
echo ""

if [ -z "$TEST_EMAIL" ] || [ -z "$TEST_PASSWORD" ]; then
  echo "${BLUE}请提供测试账户信息以获取 token${NC}"
  echo "方法 1: 使用已有账户"
  echo "  - 从生产服务器运行: rails runner \"user = User.find_by(email: 'your@email.com'); puts user.access_token.token\""
  echo ""
  echo "方法 2: 通过登录 API 获取 (当前不可用，因为登录 API 返回的不是 access_token)"
  echo ""
  read -p "请输入测试用户的 Bearer Token: " BEARER_TOKEN
else
  echo "尝试通过数据库或其他方式获取 token..."
  echo "${RED}注意: 登录接口不返回 Bearer token，需要从服务器端获取${NC}"
  echo ""
  read -p "请输入 $TEST_EMAIL 的 Bearer Token: " BEARER_TOKEN
fi

if [ -z "$BEARER_TOKEN" ]; then
  echo "${RED}✗ 错误: Token 不能为空${NC}"
  exit 1
fi

echo "${GREEN}✓ Token 已获取${NC}"
echo ""

# 步骤 2: 测试删除接口 (有效 token)
echo "${YELLOW}步骤 2: 测试删除接口 (有效 Bearer Token)${NC}"
echo "请求: DELETE $API_BASE/user/delete"
echo ""

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json")

HTTP_BODY=$(echo "$DELETE_RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $HTTP_CODE"
echo "响应: $HTTP_BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
  echo "${GREEN}✓ 测试通过: 账户删除成功${NC}"
  DELETION_SUCCESS=true
elif [ "$HTTP_CODE" = "401" ]; then
  echo "${YELLOW}⚠ Token 无效或已过期${NC}"
  DELETION_SUCCESS=false
else
  echo "${RED}✗ 测试失败: HTTP $HTTP_CODE${NC}"
  DELETION_SUCCESS=false
fi
echo ""

# 步骤 3: 测试无效 token
echo "${YELLOW}步骤 3: 测试无效 Bearer Token${NC}"
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Authorization: Bearer invalid_token_xyz123" \
  -H "Content-Type: application/json")

INVALID_BODY=$(echo "$INVALID_RESPONSE" | head -n -1)
INVALID_CODE=$(echo "$INVALID_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $INVALID_CODE"
echo "响应: $INVALID_BODY"
echo ""

if [ "$INVALID_CODE" = "401" ]; then
  echo "${GREEN}✓ 测试通过: 无效 token 正确返回 401${NC}"
  INVALID_TEST_PASS=true
else
  echo "${RED}✗ 测试失败: 应返回 401，实际返回 $INVALID_CODE${NC}"
  INVALID_TEST_PASS=false
fi
echo ""

# 步骤 4: 测试缺失 Authorization header
echo "${YELLOW}步骤 4: 测试缺失 Authorization Header${NC}"
NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_BASE/user/delete" \
  -H "Content-Type: application/json")

NO_AUTH_BODY=$(echo "$NO_AUTH_RESPONSE" | head -n -1)
NO_AUTH_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n 1)

echo "HTTP 状态码: $NO_AUTH_CODE"
echo "响应: $NO_AUTH_BODY"
echo ""

if [ "$NO_AUTH_CODE" = "401" ]; then
  echo "${GREEN}✓ 测试通过: 缺失 header 正确返回 401${NC}"
  NO_AUTH_TEST_PASS=true
else
  echo "${RED}✗ 测试失败: 应返回 401，实际返回 $NO_AUTH_CODE${NC}"
  NO_AUTH_TEST_PASS=false
fi
echo ""

# 步骤 5: 验证删除效果 (如果步骤 2 成功)
if [ "$DELETION_SUCCESS" = true ] && [ -n "$TEST_EMAIL" ] && [ -n "$TEST_PASSWORD" ]; then
  echo "${YELLOW}步骤 5: 验证账户已删除 (尝试登录)${NC}"
  VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/register/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

  VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | head -n -1)
  VERIFY_CODE=$(echo "$VERIFY_RESPONSE" | tail -n 1)

  echo "HTTP 状态码: $VERIFY_CODE"
  echo "响应: $VERIFY_BODY"
  echo ""

  if [ "$VERIFY_CODE" = "400" ] || echo "$VERIFY_BODY" | grep -q "邮箱或密码错误"; then
    echo "${GREEN}✓ 验证通过: 用户已被完全删除${NC}"
    VERIFY_TEST_PASS=true
  else
    echo "${RED}✗ 验证失败: 用户可能未被完全删除${NC}"
    VERIFY_TEST_PASS=false
  fi
  echo ""
fi

# 总结
echo "================================================"
echo "  测试总结"
echo "================================================"
echo ""
echo "测试环境: $PROD_URL"
echo ""
echo "测试结果:"
echo "  - 有效 token 删除: $([ "$DELETION_SUCCESS" = true ] && echo "${GREEN}通过${NC}" || echo "${RED}失败/未测试${NC}")"
echo "  - 无效 token 401: $([ "$INVALID_TEST_PASS" = true ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
echo "  - 缺失 header 401: $([ "$NO_AUTH_TEST_PASS" = true ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
if [ -n "$VERIFY_TEST_PASS" ]; then
  echo "  - 删除后验证: $([ "$VERIFY_TEST_PASS" = true ] && echo "${GREEN}通过${NC}" || echo "${RED}失败${NC}")"
fi
echo ""

# 判断整体结果
if [ "$INVALID_TEST_PASS" = true ] && [ "$NO_AUTH_TEST_PASS" = true ]; then
  echo "${GREEN}✅ 核心功能测试通过！接口工作正常。${NC}"
  exit 0
else
  echo "${RED}❌ 部分测试失败，请检查接口实现。${NC}"
  exit 1
fi
