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
if [ -f "/home/agent/.config/github-app/current-token" ]; then
    echo "🔑 Configuring GitHub App credential helper..."
    git config --global credential.helper "/home/agent/.local/bin/git-credential-mount.sh"
    echo "✅ GitHub App credential helper configured"
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
