# Architecture

## Topology
Windows host
└── NixOS WSL2 (l3rn4-nix)
    ├── mihomo (native, 127.0.0.1:7890)
    ├── Docker network `agent-net` (internal)
    │   ├── aggregator (only service with outbound access)
    │   ├── opencode (optional)
    │   ├── deepseek-harness (optional)
    │   └── ...
    └── ...

## Traffic & Network
- **agent-net**: Standard bridge network (NOT internal). Agents need outbound internet for `git`, `npm`, and web search.
- **Aggregator (FreeLLMAPI)**: Routes LLM traffic through `mihomo` proxy. Because of WSL2 quirks, it uses the hardcoded Docker bridge IP `http://172.17.0.1:7890` instead of `host.docker.internal`.
- **Agents (DSH/OpenCode)**: Use the WSL's AmneziaVPN/WARP for direct internet access. They do not use the proxy directly.

## Components
- **l3rn4-nix** — OS, Docker, mihomo. Unaware of hydr4 internals.
- **aggregator** — OpenAI-compatible proxy, provider failover.
- **agents** — interchangeable containers, same contract.
