#!/bin/bash

# Configuration
API_URL="http://localhost:8080"
EMAIL="test_check_in_$(date +%s)@example.com"
NICKNAME="CheckInTester"
PASSWORD="Password123!"

echo "======================================"
echo "1. Registering new user..."
echo "======================================"
echo "Creating a test user directly via rails runner..."
docker exec chatwoot-rails-1 bundle exec rails runner "
User.find_by(email: '$EMAIL')&.destroy
u = User.create!(email: '$EMAIL', name: '$NICKNAME', password: '$PASSWORD', password_confirmation: '$PASSWORD', confirmed_at: Time.current)
u.save!
"

echo -e "\n======================================"
echo "2. Logging in..."
echo "======================================"
LOGIN_RESP=$(curl -s -X POST "$API_URL/api/mobile/register/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }')

echo "$LOGIN_RESP"
TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('access_token', 'null'))")
INITIAL_BALANCE=$(echo "$LOGIN_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('balance', 'null'))")

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "Login failed or token missing!"
  exit 1
fi

echo -e "\nAccess Token acquired: $TOKEN"
echo "Initial Balance: $INITIAL_BALANCE"

echo -e "\n======================================"
echo "3. Performing 1st Check-In..."
echo "======================================"
CHECKIN_1_RESP=$(curl -s -X POST "$API_URL/api/mobile/user/check_in" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$CHECKIN_1_RESP"

echo -e "\n======================================"
echo "4. Performing 2nd Check-In (Should fail)..."
echo "======================================"
CHECKIN_2_RESP=$(curl -s -X POST "$API_URL/api/mobile/user/check_in" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$CHECKIN_2_RESP"

echo -e "\n======================================"
echo "5. Logging in again to verify balance..."
echo "======================================"
curl -s -X POST "$API_URL/api/mobile/register/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }'
echo ""


