# Contracts

## Agent → Aggregator
- Endpoint: `http://aggregator:3001/v1`
- Format: OpenAI-compatible (`/v1/models`, `/v1/chat/completions`).
- Tool calling must be preserved end-to-end.
- Agents must not call providers directly.

## Aggregator → Upstream
- Outbound HTTP(S) via `http://host.docker.internal:7890` (mihomo).
- Direct internet from the container is disabled by the network policy.

## Filesystem
- Agents see only `/workspace`.
- Host path: `./workspace`.
- No access to WSL home, Windows drives, Docker socket, or `.env`.

## UI
- Agent web UI ports bind to `127.0.0.1` on the host.
- Default: no `0.0.0.0` exposure.

## Secrets
- `.env` is gitignored; `.env.example` holds placeholders only.
- Provider keys are injected into the aggregator only, never into agents.

## Swapping components
- Aggregator: change image tag in `compose.yaml`. No Nix rebuild.
- Agent: add/remove a compose fragment in `agents/`. No Nix rebuild.
