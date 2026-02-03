#!/bin/bash
# Manual CURL test for token login
# Usage: ./manual_test_token_login.sh <access_token> [base_url]

if [ -z "$1" ]; then
  echo "Usage: $0 <access_token> [base_url]"
  echo "Example: $0 my_secret_token http://localhost:3000"
  exit 1
fi

TOKEN=$1
BASE_URL=${2:-"http://localhost:3000"}

echo "----------------------------------------"
echo "Testing Token Login"
echo "URL: $BASE_URL/api/mobile/register/login"
echo "Token: $TOKEN"
echo "----------------------------------------"

curl -v -X POST "$BASE_URL/api/mobile/register/login" \
  -H "Content-Type: application/json" \
  -d "{\"access_token\": \"$TOKEN\"}"

echo -e "\n----------------------------------------"
echo "Done."
