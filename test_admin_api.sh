#!/bin/bash
API_URL="http://172.18.88.87:20108"

echo "1. Login..."
LOGIN_RES=$(curl -s -X POST "$API_URL/api/mobile/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "john@acme.inc", "password": "Password123!"}')

echo $LOGIN_RES
TOKEN=$(echo $LOGIN_RES | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo -e "\nTOKEN: $TOKEN\n"

echo "2. Stats..."
curl -s "$API_URL/api/mobile/admin/stats" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n3. Users..."
curl -s "$API_URL/api/mobile/admin/users?per_page=1" \
  -H "Authorization: Bearer $TOKEN"
echo ""
