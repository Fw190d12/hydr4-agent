# hydr4-agent Roadmap & Deferred Work

Этот файл фиксирует архитектурные улучшения, которые мы осознанно отложили.
Они не блокируют текущую работу, но должны быть выполнены, когда появится время.

---

## 1. Migrate Traefik from `hydr4-agent` to `l3rn4-nix`

**Status:** Pending
**Priority:** Medium
**Created:** 2026-11-12
**Related:** `compose/traefik.yaml`, ADR-003

### Context

На этапе первичной интеграции Traefik был добавлен прямо в `compose/traefik.yaml` внутри `hydr4-agent`. Это было быстрое решение, чтобы получить красивые локальные домены (`agent.localhost`, `api.localhost`) без сложной настройки сетей.

Однако по принципу разделения ответственности:
- **`l3rn4-nix`** — это инфраструктурный слой (NixOS + Docker + mihomo + шлюзы).
- **`hydr4-agent`** — это приложение (агрегатор + агенты).

Traefik — это **сетевой шлюз**, такой же как `mihomo`. Его место — в `l3rn4-nix`. Это также позволит через единый Traefik открывать дашборд `mihomo`, будущие self-hosted-сервисы и т.д.

### Goal

Перенести Traefik из `hydr4-agent` в `l3rn4-nix` так, чтобы:
1. Traefik жил на уровне хоста (запускается через `l3rn4-nix`).
2. `hydr4-agent` только *объявлял* свои сервисы через Docker-лейблы.
3. Через тот же Traefik был доступен дашборд `mihomo` (например, `http://mihomo.localhost`).
4. Будущие проекты могли подключаться к тому же Traefik без второго экземпляра.

### Plan for `l3rn4-nix`

Задача для агента `l3rn4-nix`:

1. Создать Docker Compose-проект (например, `~/infra/`) для системных сервисов.
2. Добавить Traefik v3.7 с конфигурацией:
   - `--providers.docker=true`
   - `--providers.docker.exposedbydefault=false`
   - `--providers.docker.network=traefik-net`
   - `--entryPoints.web.address=:80`
   - `--api.insecure=true`
3. Создать внешнюю Docker-сеть `traefik-net`.
4. Пробросить порты `127.0.0.1:80` и `127.0.0.1:8080`.
5. Добавить в `mihomo` (или его дашборд) лейблы:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.mihomo.rule=Host(`mihomo.localhost`)"
     - "traefik.http.routers.mihomo.entrypoints=web"
     - "traefik.http.services.mihomo.loadbalancer.server.port=<mihomo_dashboard_port>"
