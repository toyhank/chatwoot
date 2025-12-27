#!/bin/bash

# 测试邮箱注册登录接口
# 使用前请确保 Rails 服务正在运行在端口 8080

BASE_URL="http://localhost:8080/api/mobile/register"

echo "========================================="
echo "测试邮箱注册登录接口"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试邮箱
TEST_EMAIL="test$(date +%s)@example.com"

echo -e "${YELLOW}1. 测试检查邮箱是否可用${NC}"
echo "GET ${BASE_URL}/check_email?email=${TEST_EMAIL}"
echo ""
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "${BASE_URL}/check_email?email=${TEST_EMAIL}")
http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_CODE/d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ 请求成功 (HTTP $http_code)${NC}"
else
    echo -e "${RED}✗ 请求失败 (HTTP $http_code)${NC}"
fi
echo "响应:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""
echo "========================================="
echo ""

echo -e "${YELLOW}2. 测试发送验证码${NC}"
echo "POST ${BASE_URL}/send_code"
echo "Body: {\"email\": \"${TEST_EMAIL}\"}"
echo ""
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\"}" \
    "${BASE_URL}/send_code")
http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_CODE/d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ 请求成功 (HTTP $http_code)${NC}"
    # 尝试提取验证码（实际情况下需要查看邮件或数据库）
    echo "提示: 验证码已发送到邮箱，请查看邮件或数据库获取验证码"
else
    echo -e "${RED}✗ 请求失败 (HTTP $http_code)${NC}"
fi
echo "响应:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""
echo "========================================="
echo ""

echo -e "${YELLOW}3. 测试用户注册${NC}"
echo "注意: 需要先发送验证码，然后使用正确的验证码"
echo "POST ${BASE_URL}/register"
echo "Body: {\"email\": \"${TEST_EMAIL}\", \"code\": \"123456\", \"password\": \"password123\"}"
echo ""
read -p "请输入验证码 (或按回车使用 123456): " code
code=${code:-123456}

response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\", \"code\": \"${code}\", \"password\": \"password123\", \"nickname\": \"测试用户\"}" \
    "${BASE_URL}/register")
http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_CODE/d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ 注册成功 (HTTP $http_code)${NC}"
else
    echo -e "${RED}✗ 注册失败 (HTTP $http_code)${NC}"
fi
echo "响应:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""
echo "========================================="
echo ""

echo -e "${YELLOW}4. 测试用户登录${NC}"
echo "POST ${BASE_URL}/login"
echo "Body: {\"email\": \"${TEST_EMAIL}\", \"password\": \"password123\"}"
echo ""
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\", \"password\": \"password123\"}" \
    "${BASE_URL}/login")
http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_CODE/d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ 登录成功 (HTTP $http_code)${NC}"
else
    echo -e "${RED}✗ 登录失败 (HTTP $http_code)${NC}"
fi
echo "响应:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""
echo "========================================="
echo ""

echo "测试完成！"
echo "使用的测试邮箱: ${TEST_EMAIL}"

