# hydr4-agent State Analysis and Developer Guide

> **Generated for:** The developer agent maintaining and extending `hydr4-agent`.
> **Scope:** Complete current state analysis of the `hydr4-agent` project structure, configurations, docker composition, and integration mechanisms.

---

## 1. Project Overview & Core Principles

`hydr4-agent` is a modular, multi-agent sandbox designed for running in a NixOS/WSL2 environment (`l3rn4-nix`). It provides secure, isolated agent execution where components communicate strictly through defined interfaces.

### Core Principles
- **One agent — one container.** Modular deployment of independent agent runtimes (e.g., DeepSeek Harness / `agent-dsh`).
- **Workspace Isolation:** Agents have strict access only to `./workspace` mounted inside the container.
- **Traffic Control:** Agents have no direct unmonitored internet access; all LLM traffic goes through the local OpenAI-compatible aggregator (`freellmapi`).
- **Secrets Management:** Secrets (`.env`) never enter Git; `.env.example` provides placeholders.

---

## 2. Project Layout & Current Inventory

```text
hydr4-agent/
├── .env.example            # Template for aggregator keys and proxy settings
├── .gitignore              # Ignores .env, workspace contents, etc.
├── compose.yaml            # Docker Compose orchestration (aggregator + agent-dsh)
├── hydra                   # Control CLI script (start, stop, web, cli)
├── README.md               # High-level overview and design goals
├── aggregator/             # FreeLLMAPI aggregator configs and documentation
│   └── README.md
├── agents/                 # Per-agent compose fragments and configurations
│   └── README.md
├── docs/                   # Architectural notes, contracts, and decisions (ADRs)
│   ├── ARCHITECTURE.md     # Topology and network flows
│   ├── CONTRACTS.md        # Component interfaces and security boundaries
│   └── DECISIONS.md        # Architectural Decision Records (ADR-0001)
├── dsh-config/             # DeepSeek Harness (DSH) configuration
│   └── settings.yaml       # Provider mapping to local aggregator endpoint
├── scripts/                # Utility and verification scripts
│   └── smoke-test.sh       # Comprehensive integration tests (proxy, API, tool calling)
└── workspace/              # Shared working directory mounted into agents (.gitkeep)
```

---

## 3. Infrastructure & Services (`compose.yaml`)

The system is orchestrated via Docker Compose (`hydr4-agent/compose.yaml`) within the Docker network `hydr4-agent-net`:

1. **`aggregator` (Service Name: `hydr4-aggregator`)**
   - **Image:** `ghcr.io/tashfeenahmed/freellmapi:latest`
   - **Ports:** `3001:3001`
   - **Environment:**
     - `PORT=3001`, `HOST_BIND=0.0.0.0`
     - `ENCRYPTION_KEY=${ENCRYPTION_KEY}`
     - `HTTP_PROXY` / `HTTPS_PROXY`: `http://172.17.0.1:7890` (routing through host mihomo proxy via Docker bridge IP)
   - **Volumes:**
     - `freellmapi-data:/app/server/data` (persistent state for aggregator)
   - **Role:** Central OpenAI-compatible LLM proxy with upstream provider failover and encryption.

2. **`agent-dsh` (Service Name: `hydr4-agent-dsh`)**
   - **Image:** `smanx/deepseek-harness:latest`
   - **Profiles:** `dsh` (requires explicit `--profile dsh` or `./hydra start`)
   - **Ports:** `3080:3080` (Web UI accessible at `http://localhost:3080`)
   - **Volumes:**
     - `./workspace:/workspace` (isolated working directory)
     - `dsh-home:/root/.dsh` (persists DSH state / settings)
   - **Environment:**
     - `DSH_WORKSPACE=/workspace`
     - `OPENAI_API_KEY=${FREELMAPI_UNIFIED_KEY}` (authenticated against the local aggregator)
   - **Role:** DeepSeek Harness agent environment.

---

## 4. Configuration & Integrations

### DeepSeek Harness Configuration (`hydr4-agent/dsh-config/settings.yaml` / mounted/linked in container)
Configures DSH to treat the local aggregator as its upstream provider using OpenAI completions format:
```yaml
agent-default-model:
  provider: hydra
  model: gemini-3.5-flash-lite

llm-pi-ai:
  providers:
    hydra:
      api: openai-completions
      baseURL: http://aggregator:3001/v1
      apiKeyEnv: OPENAI_API_KEY
      models:
        - id: gemini-3.5-flash-lite
```

### Control Script (`hydr4-agent/hydra`)
Provides a convenient CLI wrapper:
- `./hydra start` — Runs `docker compose --profile dsh up -d`
- `./hydra stop` — Runs `docker compose --profile dsh down`
- `./hydra web` — Prints Web UI access URL (`http://localhost:3080`)
- `./hydra cli` — Opens an interactive bash shell inside `hydr4-agent-dsh`

---

## 5. Testing & Verification (`scripts/smoke-test.sh`)

The integration test suite (`hydr4-agent/scripts/smoke-test.sh`) validates 4 crucial tiers:
1. **Container Proxy Access:** Verifies that the aggregator container can reach external APIs through the host mihomo proxy (`http://172.17.0.1:7890`).
2. **Aggregator Health Check:** HTTP GET to `http://127.0.0.1:3001/healthz` returns `200 OK`.
3. **Tool Calling from WSL (Host perspective):** Sends a chat completion request with tool definitions (`get_weather`) to `http://127.0.0.1:3001/v1/chat/completions` using `$FREELMAPI_UNIFIED_KEY` and confirms `tool_calls` are correctly returned.
4. **Tool Calling from inside Docker:** Executes the same API check internally within the container network.

---

## 6. Current State Summary & Next Steps for Development

- **Current State:** Bootstrap & Foundation complete. The aggregator is configured and containerized, the DSH agent container (`agent-dsh`) is integrated with profiles, proxy routing via Docker bridge (`172.17.0.1:7890`) is established, and automated smoke testing is in place.
- **Ready for Development:** You can start containers via `./hydra start`, access the DSH Web UI at `http://localhost:3080`, and extend agent behaviors inside `./workspace` or add new agent containers under `agents/`.
