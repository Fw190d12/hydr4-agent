# Decisions (Architectural Decision Records)

## ADR-0001 — Aggregator runs in Docker (Variant A)

**Status:** Accepted.

**Context:** Two options were proposed — Docker (A) or native systemd via a Nix module (B).

**Decision:** Variant A.

**Rationale:**
- `l3rn4-nix` explicitly does not want ownership of the aggregator.
- Swapping aggregators must not require `nix-rebuild`.
- Aggregator is application logic, not infrastructure.
- Agents and aggregator share one Docker network; no host-loopback ambiguity.
- Secrets live in `.env` (gitignored) for development, with a clear path to Docker secrets later.

**Consequences:**
- mihomo must accept connections from the Docker bridge (see prerequisites in README).
- Aggregator image pinning becomes part of the repo.

---

## ADR-002 — Resolving WSL2 Mirrored Network Issues

**Status:** Accepted.

**Context:** 
In WSL2 with `networkingMode=mirrored`, Docker's default `userland-proxy` conflicted with the host's NAT rules. This caused external POST requests (like those to the aggregator) to be silently dropped or time out.

**Decision:**
Disable `userland-proxy` in the Docker daemon settings (`virtualisation.docker.daemon.settings = { userland-proxy = false; };`) inside `l3rn4-nix`. 

**Consequences:**
- Docker now relies solely on `iptables` for port forwarding.
- Host-to-container networking works reliably in mirrored mode.
- Network routing is documented in `l3rn4-nix` configuration.

---

## ADR-003 — Agent Network Access & Hardcoded Proxy IP

**Status:** Accepted.

**Context:** 
The code reviewer flagged that `agent-net` is not `internal: true` and that `172.17.0.1` is hardcoded.

**Decision:** 
We deliberately keep standard bridge networking so agents can run `git clone` and `npm install`. We also hardcode `172.17.0.1` because WSL2's mirrored networking frequently breaks `host.docker.internal`.

**Consequences:**
- Agents have full egress to the internet (bypassing mihomo for raw traffic).
- The setup is WSL2-specific. To mitigate key leakage, agents only receive the `HYDRA_API_KEY` (aggregator key), not the raw provider keys.

---

## ADR-004 — UID/GID Alignment for Universal Agent Image

**Status:** Resolved.

**Context:**
The base image `node:22-slim` comes with a pre-existing `node` user that occupies UID 1000. Our Dockerfile originally created an `agent` user, which received UID 1001. However, the `compose.yaml` runs the container as `user: "1000:1000"`. This UID mismatch caused `Permission denied` errors when trying to write to volumes or bind mounts.

**Decision:**
Modify `docker/universal-agent/Dockerfile` to explicitly align the internal UID with the host:
1. Remove the default user: `RUN userdel -r node || true`
2. Create the `agent` user with explicit UID 1000: `RUN useradd -u 1000 -U -m -s /bin/bash agent`
3. Set ownership of home directories before switching users.

**Consequences:**
- Manual `chown` workarounds are no longer needed.
- Volumes and bind mounts created by Docker automatically inherit the correct UID 1000, matching the host user.
- The image is fully portable and works out-of-the-box on WSL2.

---

## ADR-005 — Centralized Data Storage (Bind Mounts instead of Named Volumes)

**Status:** Accepted.

**Context:**
Initially, the project used Docker Named Volumes (`agent-data`, `opencode-data`, etc.) for persistent storage. While convenient, it makes backups and data inspection difficult because the data is hidden inside Docker's system directories (`/var/lib/docker/volumes/`).

**Decision:**
Migrate all persistent storage to explicit **Bind Mounts** located in a centralized directory outside the Git repository: `~/hydr4-data/`.

**Structure:**
- `~/hydr4-data/aggregator/` — FreeLLMAPI database.
- `~/hydr4-data/agent/config/` — Agent configurations (`.config`).
- `~/hydr4-data/agent/local-share/` — OpenCode chat history and sessions.
- `~/hydr4-data/secrets/` — (Future) SSH keys and sensitive tokens.

**Consequences:**
- **Pros:** Easy backups (just copy the folder), transparent data access, strict separation of code (Git) and state (Disk).
- **Cons:** Users must manually ensure the directory exists and has the correct UID/GID permissions (`1000:1000`).
