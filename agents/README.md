# Agents

Each agent lives in its own container and its own compose fragment.

Rules:
- Uses `http://aggregator:8080/v1` as base URL.
- Mounts only `../workspace:/workspace`.
- Joins `agent-net`.
- No `extra_hosts`, no outbound internet.
- UI binds to `127.0.0.1`.

Adding an agent: drop `agents/<name>/compose.yaml`, include it from the root compose.
