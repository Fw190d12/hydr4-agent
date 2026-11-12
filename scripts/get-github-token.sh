#!/usr/bin/env bash

# Проверка аргументов
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <APP_ID> <INSTALLATION_ID> <PATH_TO_PRIVATE_KEY>"
    exit 1
fi

APP_ID=$1
INSTALLATION_ID=$2
PRIVATE_KEY=$3

# 1. Генерируем JWT
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
NOW=$(date +%s)
EXP=$((NOW + 600)) # Токен живет 10 минут
PAYLOAD=$(echo -n "{\"iat\":${NOW},\"exp\":${EXP},\"iss\":\"${APP_ID}\"}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
SIGNATURE=$(echo -n "${HEADER}.${PAYLOAD}" | openssl dgst -sha256 -sign "${PRIVATE_KEY}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
JWT="${HEADER}.${PAYLOAD}.${SIGNATURE}"

# 2. Получаем Installation Token
TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens" | jq -r .token)

# 3. Выводим токен
if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Error: Failed to get token" >&2
    exit 1
fi

echo "$TOKEN"
