# Aggregator

OpenAI-compatible proxy that pools free tiers and fails over on 429.

Candidate: zerogateway. Alternatives: LiteLLM, FreeLLMAPI.

Constraints:
- Image is pinned, not `latest`.
- Reads keys from `.env`.
- Uses `http://host.docker.internal:7890` for outbound traffic.
- Only service with `extra_hosts`.
- Health endpoint must be checked before agents start.
