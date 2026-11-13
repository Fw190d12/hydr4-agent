# hydr4-agent Roadmap & Deferred Work

Этот файл фиксирует архитектурные улучшения, которые мы осознанно отложили.
Они не блокируют текущую работу, но должны быть выполнены, когда появится время.

---

## ✅ Completed (Archive)

### 1. Migrate Traefik from `hydr4-agent` to `l3rn4-nix`
**Status:** Done (2026-11-13)
**Related:** `compose/traefik.yaml` (deleted), ADR-008

**Summary:**
Traefik был перенесен на уровень хоста (`l3rn4-nix`). Теперь `hydr4-agent` не управляет прокси-сервером. Вместо этого мы объявляем наши сервисы через Docker-лейблы и подключаемся к внешней сети `traefik-net`. 
На уровне `l3rn4-nix` также настроен безопасный доступ к Docker через `docker-socket-proxy` и добавлены роуты для `mihomo.localhost` и `traefik.localhost`. 
Документация по сетевой архитектуре теперь ведется в `l3rn4-nix/NETWORK_AUDIT.md`.

---

## 🚀 Upcoming & Deferred Work

*Этот список будет пополняться по мере развития проекта.*

### 2. Автоматическая ротация секретов
- **Status:** Pending
- **Context:** Сейчас `ENCRYPTION_KEY` и `FREELMAPI_UNIFIED_KEY` меняются вручную (через `.env` и UI).
- **Goal:** Реализовать процедуру или скрипт для их безопасной ротации без простоя сервисов.

### 3. Харденинг агента: `read_only: true`
- **Status:** Pending
- **Context:** Root-файловая система контейнера `agent` сейчас доступна для записи. 
- **Goal:** Добавить `read_only: true` в `compose/agents.yaml` для `agent`, и смонтировать `tmpfs` для тех директорий, куда OpenCode пытается писать (например, `/tmp`), чтобы защитить систему от изменений.

### 4. Добавление `dsh` (DeepSeek Harness) как альтернативного агента
- **Status:** Pending
- **Context:** Наша архитектура позволяет запускать разных агентов через `AGENT_TYPE`. Сейчас используется OpenCode.
- **Goal:** Проверить работу DSH в нашей песочнице (второй профиль в `compose.yaml`), сравнить его с OpenCode и, если нужно, добавить кастомные инструкции в `entrypoint.sh`.

### 5. Мониторинг и Observability
- **Status:** Pending
- **Context:** Сейчас мы видим только логи Docker и дашборд FreeLLMAPI.
- **Goal:** Развернуть Prometheus + Grafana (или другой стек) для сбора метрик по токенам, задержкам LLM и статусу контейнеров.

### 6. Автоматизация GitHub Token Refresher (Systemd)
- **Status:** Pending
- **Context:** Сейчас `hydra` запускает фоновый цикл обновления токена.
- **Goal:** В идеале перенести это в `systemd` таймер на стороне `l3rn4-nix`, чтобы токен обновлялся даже без запущенного `hydra`.
