# Backend Deployment Evolution

Status: Phase 1 local container foundation implemented; production infrastructure remains proposed.

## Local development

Docker Compose runs `api`, `worker`, and private `redis` services. Applications do not connect to Redis until Phase 2. Supabase remains the repository's existing external/local Supabase environment rather than a competing PostgreSQL stack. Phase 1 configuration validates process, HTTP, CORS, proxy-trust, and throttling settings; later phases add database, Redis, queue, and auth validation alongside those integrations.

## Initial production

One DigitalOcean Droplet behind a TLS reverse proxy:

```text
reverse proxy
  -> api x1
worker x1
redis x1 (private network/container only)
Supabase hosted PostgreSQL/Auth/Storage
```

Set `TRUST_PROXY_HOPS` to the exact number of controlled proxy hops (one for this topology). Leaving it at zero ignores forwarded client addresses; trusting more hops than the deployment owns permits spoofing and weakens per-client throttling.

API and worker use multi-stage images, non-root runtime users, production-only artifacts, and graceful SIGTERM. Redis is never exposed publicly. Secrets are injected at deployment and are not baked into images.

## Horizontal evolution

```text
load balancer
  -> api xN
worker xN
shared managed/private Redis
Supabase PostgreSQL/Auth/Storage
```

Socket.IO uses the Redis adapter; presence, typing, rate limits, and active-thread state are shared. Workers coordinate through BullMQ and PostgreSQL outbox claiming. Scaling changes replicas and pool/concurrency configuration, not business code.

## Health

- `/health/live`: process and event loop responsive; no third-party dependency checks.
- `/health/ready`: startup complete, PostgreSQL reachable, Redis reachable, required adapters initialized.
- Worker readiness is expressed through container health/log/metrics rather than an HTTP server unless the deployment platform later requires a minimal probe sidecar.

## Operational safeguards

- Cap total database connections across all replicas below Supabase limits.
- Use PgBouncer-compatible behavior if the project connection endpoint requires it.
- Bound request bodies, queries, Socket.IO rooms, queue concurrency, and retention.
- Set CORS by allowlist and security headers at API bootstrap/reverse proxy.
- Back up Redis configuration only for operations; loss of Redis must not lose messages.
- Deploy additive database migrations before code that consumes them; preserve older mobile clients through the rollback window.

## Rollout sequence

1. Deploy API/worker foundation with only health endpoints.
2. Validate database and Redis readiness without chat traffic.
3. Enable HTTP reads for internal users and compare with Supabase responses.
4. Enable writes, realtime, presence/typing, and notifications in separate gates.
5. Run two-client integration tests and measured load tests on the production-equivalent topology.
6. Expand cohorts, observe errors/latency/backlog, retain Ably rollback.
7. Remove Ably secrets, Edge Function, client dependency, and database triggers only after parity and rollback-window approval.

## Capacity claims

No concurrency or throughput capacity is claimed in Phase 0. Phase 10 must report measured sockets, messages/second, reconnect storms, fanout, CPU, memory, event-loop lag, Redis behavior, PostgreSQL latency/pool saturation, and queue/outbox backlog for a named deployment size.
