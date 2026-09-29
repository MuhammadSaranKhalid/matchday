# Backend Deployment Evolution

Status: Phase 2 infrastructure implemented; AWS Lightsail deployment and media processing remain gated.

## Local development

Docker Compose runs `api`, `worker`, and private `redis` services. API and worker use validated PostgreSQL, Supabase Auth, Redis, and BullMQ configuration. Supabase remains authoritative for PostgreSQL, Auth, and Storage; Compose does not run a competing production PostgreSQL service.

## Initial production

One AWS Lightsail instance behind a TLS reverse proxy:

```text
reverse proxy
  -> api x1
worker x1
redis x1 (private network/container only)
Supabase hosted PostgreSQL/Auth/Storage
temporary media-processing volume mounted only into the worker
```

Set `TRUST_PROXY_HOPS` to the exact number of controlled proxy hops (one for this topology). Leaving it at zero ignores forwarded client addresses; trusting more hops than the deployment owns permits spoofing and weakens per-client throttling.

API and worker use multi-stage images, non-root runtime users, production-only artifacts, and graceful SIGTERM. Redis is never exposed publicly. Secrets are injected at deployment and are not baked into images. The worker volume is bounded scratch space; Supabase Storage remains the authoritative object store.

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

1. Deploy and verify the API/worker/Redis foundation on Lightsail.
2. Migrate image processing into the Nest worker and make BullMQ `media` the first active queue.
3. Verify upload, staging, processing, final Supabase Storage publication, retries, cleanup, and recovery end to end.
4. Retire the Vercel media-processing HTTP function after production parity is proven.
5. Begin chat read/write and realtime work only after the media milestone is complete.

## Capacity claims

No concurrency or throughput capacity is claimed in Phase 0. Phase 10 must report measured sockets, messages/second, reconnect storms, fanout, CPU, memory, event-loop lag, Redis behavior, PostgreSQL latency/pool saturation, and queue/outbox backlog for a named deployment size.
