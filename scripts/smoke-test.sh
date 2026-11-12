#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Загружаем ключ из .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}Ошибка: .env файл не найден!${NC}"
    exit 1
fi

if [ -z "$FREELMAPI_UNIFIED_KEY" ]; then
    echo -e "${RED}Ошибка: FREELMAPI_UNIFIED_KEY не задан в .env!${NC}"
    exit 1
fi

echo -e "${YELLOW}=== Запуск Smoke-тестов для hydr4-agent ===${NC}\n"

# 0. Узнаем у FreeLLMAPI, какая модель сейчас активна
echo -n "0. Запрос списка моделей у FreeLLMAPI... "
MODELS_JSON=$(curl -s -H "Authorization: Bearer $FREELMAPI_UNIFIED_KEY" http://127.0.0.1:3001/v1/models)

# Вытаскиваем ID первой модели из JSON (ищем паттерн "id":"...")
ACTIVE_MODEL=$(echo "$MODELS_JSON" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$ACTIVE_MODEL" ]; then
    echo -e "${RED}ОШИБКА (не удалось получить модель. Проверь ключи в дашборде)${NC}"
    # Если моделей нет, используем 'auto' как запасной вариант
    ACTIVE_MODEL="auto"
    echo -e "${YELLOW}Используем fallback: $ACTIVE_MODEL${NC}"
else
    echo -e "${GREEN}OK (Активная модель: $ACTIVE_MODEL)${NC}"
fi

# Формируем JSON-пейлоад с динамической моделью
JSON_PAYLOAD=$(cat <<EOF
{
  "model": "${ACTIVE_MODEL}",
  "messages": [{"role": "user", "content": "What is the weather in Moscow?"}],
  "tools": [{
    "type": "function",
    "function": {
      "name": "get_weather",
      "description": "Get the current weather",
      "parameters": {
        "type": "object",
        "properties": {"location": {"type": "string"}},
        "required": ["location"]
      }
    }
  }]
}
EOF
)

# 1. Проверка прокси mihomo
echo -n "1. Проверка прокси mihomo из контейнера... "
PROXY_IP=$(docker compose exec -T aggregator node -e "
const { request, ProxyAgent } = require('undici');
const proxyAgent = new ProxyAgent('http://172.17.0.1:7890');
request('https://api.ipify.org', { dispatcher: proxyAgent })
  .then(r => r.body.text()).then(ip => console.log(ip)).catch(() => console.log('FAIL'));
" 2>/dev/null | tr -d '\r\n')

if [ "$PROXY_IP" != "FAIL" ] && [ -n "$PROXY_IP" ]; then
    echo -e "${GREEN}OK (IP: $PROXY_IP)${NC}"
else
    echo -e "${RED}ОШИБКА (не удалось получить IP через прокси)${NC}"
fi

# 2. Проверка доступности API
echo -n "2. Проверка API FreeLLMAPI из WSL... "
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3001/healthz)
if [ "$HEALTH" = "200" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}ОШИБКА (HTTP $HEALTH)${NC}"
fi

# 3. Проверка Tool Calling из WSL
echo -n "3. Проверка Tool Calling из WSL (POST)... "
RESPONSE=$(curl -s --max-time 20 http://127.0.0.1:3001/v1/chat/completions \
  -H "Authorization: Bearer $FREELMAPI_UNIFIED_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

if echo "$RESPONSE" | grep -q '"tool_calls"'; then
    echo -e "${GREEN}OK (Tool Calls работают)${NC}"
else
    echo -e "${RED}ОШИБКА (Tool Calls не найдены)${NC}"
    echo -e "${YELLOW}Ответ сервера: $RESPONSE${NC}"
fi

# 4. Проверка Tool Calling изнутри Docker
echo -n "4. Проверка Tool Calling изнутри Docker... "
DOCKER_RESPONSE=$(docker compose exec -T aggregator node -e "
fetch('http://127.0.0.1:3001/v1/chat/completions', {
  method: 'POST',
  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${FREELMAPI_UNIFIED_KEY}'},
  body: JSON.stringify(${JSON_PAYLOAD})
}).then(r=>r.text()).then(console.log).catch((e)=>console.log('FAIL:', e.message))
" 2>/dev/null)

if echo "$DOCKER_RESPONSE" | grep -q '"tool_calls"'; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}ОШИБКА${NC}"
    echo -e "${YELLOW}Ответ из Docker: $DOCKER_RESPONSE${NC}"
fi
