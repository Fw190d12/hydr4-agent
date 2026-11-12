FROM node:22-slim

# Устанавливаем инструменты: Python, Git, утилиты
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    ripgrep \
    less \
    python3 \
    python-is-python3 \
    openssh-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем ttyd (веб-терминал)
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) TTYD_ARCH="x86_64" ;; \
         arm64) TTYD_ARCH="aarch64" ;; \
         *) echo "Unsupported arch"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Устанавливаем gh-token (для генерации токенов GitHub App)
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) GH_TOKEN_ASSET="linux-amd64" ;; \
         arm64) GH_TOKEN_ASSET="linux-arm64" ;; \
         *) echo "Unsupported arch"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/Link-/gh-token/releases/latest/download/${GH_TOKEN_ASSET}" -o /usr/local/bin/gh-token \
    && chmod +x /usr/local/bin/gh-token

# Добавляем ключи GitHub в системный список доверенных хостов
RUN mkdir -p /etc/ssh && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts 2>/dev/null

# Устанавливаем OpenCode и DeepSeek Harness (CLI)
RUN npm install -g @opencode/cli dsh

# Создаем пользователя
RUN userdel -r node || true

RUN useradd -u 1000 -U -m -s /bin/bash agent

# Создаем директорию конфига и даем права пользователю agent (для тома)
RUN mkdir -p /home/agent/.local/share/opencode 
RUN mkdir -p /home/agent/.config
RUN chown -R agent:agent /home/agent

USER agent

WORKDIR /workspace

# Копируем скрипт запуска
COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

ENTRYPOINT ["/home/agent/entrypoint.sh"]
