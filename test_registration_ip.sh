#!/bin/bash

# 测试注册IP功能
# 使用前请确保 Rails 服务正在运行在端口 8080

BASE_URL="http://localhost:8080/api/mobile/register"

echo "========================================="
echo "测试注册IP功能"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 生成测试邮箱
TEST_EMAIL="testip$(date +%s)@example.com"

echo -e "${BLUE}测试邮箱: ${TEST_EMAIL}${NC}"
echo ""

# 1. 检查邮箱
echo -e "${YELLOW}1. 检查邮箱是否可用${NC}"
response=$(curl -s "${BASE_URL}/check_email?email=${TEST_EMAIL}")
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# 2. 发送验证码
echo -e "${YELLOW}2. 发送验证码${NC}"
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\"}" \
    "${BASE_URL}/send_code")
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# 3. 从数据库获取验证码
echo -e "${YELLOW}3. 从数据库获取验证码${NC}"
VERIFICATION_CODE=$(docker-compose -f docker-compose.development.yaml exec -T rails bundle exec rails runner "
code = EmailVerificationCode.where(email: '${TEST_EMAIL}').order(created_at: :desc).first
puts code ? code.code : 'NOT_FOUND'
" 2>/dev/null | grep -v "warning" | grep -v "fatal" | tail -1)

if [ "$VERIFICATION_CODE" = "NOT_FOUND" ] || [ -z "$VERIFICATION_CODE" ]; then
    echo -e "${RED}✗ 无法获取验证码${NC}"
    echo "请检查邮件服务或数据库"
    exit 1
fi

echo -e "${GREEN}✓ 验证码: ${VERIFICATION_CODE}${NC}"
echo ""

# 4. 注册用户
echo -e "${YELLOW}4. 注册用户${NC}"
REGISTER_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\", \"code\": \"${VERIFICATION_CODE}\", \"password\": \"Password123!\", \"nickname\": \"测试用户IP\"}" \
    "${BASE_URL}/register")
echo "$REGISTER_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$REGISTER_RESPONSE"
echo ""

# 检查注册是否成功
if echo "$REGISTER_RESPONSE" | grep -q '"status":200'; then
    echo -e "${GREEN}✓ 注册成功${NC}"
    
    # 5. 检查用户的注册IP
    echo ""
    echo -e "${YELLOW}5. 检查用户的注册IP${NC}"
    USER_IP=$(docker-compose -f docker-compose.development.yaml exec -T rails bundle exec rails runner "
    user = User.find_by(email: '${TEST_EMAIL}')
    if user
      puts user.registration_ip || '未设置'
    else
      puts '用户未找到'
    end
    " 2>/dev/null | grep -v "warning" | grep -v "fatal" | tail -1)
    
    if [ -n "$USER_IP" ] && [ "$USER_IP" != "未设置" ] && [ "$USER_IP" != "用户未找到" ]; then
        echo -e "${GREEN}✓ 注册IP已保存: ${USER_IP}${NC}"
    else
        echo -e "${RED}✗ 注册IP未保存或为空${NC}"
    fi
    
    # 6. 检查联系人信息（如果存在）
    echo ""
    echo -e "${YELLOW}6. 检查联系人信息中的注册IP${NC}"
    CONTACT_INFO=$(docker-compose -f docker-compose.development.yaml exec -T rails bundle exec rails runner "
    user = User.find_by(email: '${TEST_EMAIL}')
    if user
      # 查找是否有对应的联系人
      contact = Contact.find_by(email: user.email)
      if contact
        puts '联系人ID: ' + contact.id.to_s
        puts '联系人邮箱: ' + (contact.email || '无')
      else
        puts '未找到对应的联系人'
      end
    end
    " 2>/dev/null | grep -v "warning" | grep -v "fatal")
    
    echo "$CONTACT_INFO"
    
else
    echo -e "${RED}✗ 注册失败${NC}"
fi

echo ""
echo "========================================="
echo "测试完成！"
echo "========================================="

