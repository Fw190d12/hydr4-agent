#!/bin/bash

# --- Git Identity Setup ---
# Используем путь в примонтированной папке .config, чтобы настройки сохранялись
export GIT_CONFIG_GLOBAL="/home/agent/.config/.gitconfig"

if [ ! -f "$GIT_CONFIG_GLOBAL" ]; then
    echo "⚙️  Initializing default Git identity..."
    git config --global user.name "Hydra AI Agent"
    # Генерируем уникальный email на основе hostname контейнера, чтобы не хардкодить PII
    git config --global user.email "agent@$(hostname).local"
fi
# --------------------------

# --- GitHub App Token Setup ---
if [ -n "$GITHUB_APP_ID" ] && [ -n "$GITHUB_INSTALLATION_ID" ] && [ -f "/home/agent/.config/github-app/private-key.pem" ]; then
    echo "🔑 Generating GitHub App token..."
    TOKEN=$(gh-token generate \
        --key /home/agent/.config/github-app/private-key.pem \
        --app-id "$GITHUB_APP_ID" \
        --installation-id "$GITHUB_INSTALLATION_ID" | jq -r .token)
    
    if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        git config --global credential.helper store
        echo "https://x-access-token:${TOKEN}@github.com" > /home/agent/.git-credentials
        echo "✅ GitHub App token configured"
    else
        echo "❌ Failed to generate GitHub App token"
    fi
fi
# ------------------------------

if [ "$AGENT_TYPE" = "opencode" ]; then
    echo "🚀 Запуск OpenCode Web Server..."
    exec opencode serve --hostname 0.0.0.0 --port 4096
    
elif [ "$AGENT_TYPE" = "dsh" ]; then
    echo "🚀 Запуск DeepSeek Harness..."
    # Запускаем DSH (порт 3080)
    exec dsh web --port 3080 --host 0.0.0.0
    
else
    echo "❌ Неизвестный AGENT_TYPE: $AGENT_TYPE. Доступны: opencode, dsh."
    exec bash
fi
