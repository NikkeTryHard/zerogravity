# VPS Deployment Guide

- **Status**: Active
- **Last validated**: 2026-03-04
- **Related docs**: [`docker.md`](docker.md), [`api.md`](api.md), [`zg.md`](zg.md), [`index.md`](index.md)

Use this guide to deploy ZeroGravity on a remote Linux VPS with a minimal, secure baseline. The exact package manager, cloud firewall UI, and DNS tooling vary by provider, but the flow below stays the same.

## 1) Minimal secure deployment flow

1. **Create a non-root user** (with `sudo`) and disable direct SSH root login.
2. **Install Docker + Compose plugin** from your distro's official or vendor-supported repository.
3. **Create a deployment directory** (for example, `/opt/zerogravity`) owned by your deploy user.
4. **Generate config files**:

   ```bash
   cd /opt/zerogravity
   zg docker-init
   ```

5. **Add accounts** (`accounts.json` volume mount, or `ZEROGRAVITY_ACCOUNTS` environment variable).
6. **Set an API key** (required for remote exposure; see below).
7. **Start the service**:

   ```bash
   docker compose up -d
   ```

8. **Verify health**:

   ```bash
   curl -fsS http://127.0.0.1:8741/health
   ```

## 2) API key protection (`ZEROGRAVITY_API_KEY`)

Set one or more keys in your deployment environment:

```bash
# .env or shell export
ZEROGRAVITY_API_KEY="replace-with-a-long-random-secret"
# optional multi-key rotation:
# ZEROGRAVITY_API_KEY="key-a,key-b,key-c"
```

Client requests must include one of the supported auth headers:

- `Authorization: Bearer <key>`
- `x-api-key: <key>`
- `x-goog-api-key: <key>`

Examples:

```bash
curl https://api.example.com/v1/chat/completions \
  -H "Authorization: Bearer $ZEROGRAVITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gemini-3-flash","messages":[{"role":"user","content":"hello"}]}'

curl https://api.example.com/v1/messages \
  -H "x-api-key: $ZEROGRAVITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"opus-4.6","max_tokens":256,"messages":[{"role":"user","content":"hello"}]}'
```

## 3) Firewall posture

At both VPS firewall and host firewall layers:

- **Allow inbound only the intended public API port** (for example `443` if behind TLS reverse proxy, or `8741` for direct HTTP).
- **Restrict SSH** (`22`) to your admin IP ranges.
- **Do not expose admin/sensitive ports** publicly (`2375/2376` Docker API, database ports, metrics/debug ports, etc.).
- **Allow established outbound traffic** so the proxy can reach upstream services.

If possible, bind internal-only services to loopback (`127.0.0.1`) and publish only the single entrypoint port.

## 4) Reverse proxy + TLS termination options

For public internet access, terminate HTTPS in front of ZeroGravity using any standard reverse proxy (Nginx, Caddy, Traefik, HAProxy, cloud LB, etc.):

- Listener on `443` with a valid certificate.
- Proxy upstream to `http://127.0.0.1:8741`.
- Preserve request bodies and streaming responses.
- Forward common headers (`Host`, `X-Forwarded-For`, `X-Forwarded-Proto`).

If you keep ZeroGravity on plain HTTP internally, ensure only the reverse proxy can reach port `8741`.

## 5) Healthcheck and restart policy

Use `restart: unless-stopped` and a `/health` probe in Compose:

```yaml
services:
  zerogravity:
    image: ghcr.io/nikketryhard/zerogravity:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:8741:8741"
    environment:
      - ZEROGRAVITY_API_KEY=${ZEROGRAVITY_API_KEY}
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:8741/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
```

This gives automatic restart after reboot/crash and a reliable readiness signal for orchestration or external monitoring.

## 6) Claude Code remote endpoint example

When using Anthropic-compatible clients from your laptop/workstation, point to your remote ZeroGravity endpoint instead of localhost.

```bash
export ANTHROPIC_BASE_URL="https://api.example.com"
export ANTHROPIC_AUTH_TOKEN="replace-with-your-zerogravity-api-key"
```

Then run Claude Code normally. Requests go to:

- `POST $ANTHROPIC_BASE_URL/v1/messages`
- Auth via `x-api-key: $ANTHROPIC_AUTH_TOKEN`

If you run without TLS (not recommended on public networks), use `http://<vps-ip>:8741` only behind strict firewall/IP allowlists.
