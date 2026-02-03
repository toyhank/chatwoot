#!/bin/bash
# Test token login functionality inside Docker
# Usage: docker compose -f docker-compose.development.yaml exec rails /app/test_token_login.sh

set -e

BASE_URL="http://localhost:3000"
EMAIL="token_login_test_$(date +%s)@example.com"
PASSWORD="password123"

echo "=================================================="
echo "Testing Token Login"
echo "=================================================="

# 1. Create a user and get token using Rails runner
echo ""
echo "Creating test user..."

USER_DATA=$(bundle exec rails runner "
  user = User.create!(
    email: '$EMAIL',
    password: '$PASSWORD',
    password_confirmation: '$PASSWORD',
    name: 'Token Tester',
    confirmed_at: Time.current
  )
  puts user.access_token.token
  puts user.id
" 2>/dev/null)

TOKEN=$(echo "$USER_DATA" | head -n 1)
UID=$(echo "$USER_DATA" | tail -n 1)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to create user or get token"
  exit 1
fi

echo "✅ User created."
echo "   ID: $UID"
echo "   Email: $EMAIL"
echo "   Token: $TOKEN"

# 2. Test Login with Token
echo ""
echo "Testing POST /api/mobile/register/login with access_token..."

RESP=$(curl -s -X POST "$BASE_URL/api/mobile/register/login" \
  -H "Content-Type: application/json" \
  -d "{\"access_token\": \"$TOKEN\"}")

# Check if response contains user email/id indicating success
# The success response structure is:
# { "status": 200, "msg": "ok", "data": { "uid": ..., "email": ... } }

if echo "$RESP" | grep -q "$EMAIL"; then
  echo "✅ Login Successful!"
  echo "Response: $RESP"
else
  echo "❌ Login Failed"
  echo "Response: $RESP"
  exit 1
fi

echo ""
echo "=================================================="
echo "Test Passed!"
echo "=================================================="
