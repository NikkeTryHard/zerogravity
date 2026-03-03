# Docker Guide

- **Status**: Active
- **Last validated**: 2026-03-03
- **Related docs**: [`README.md`](README.md), [`api.md`](api.md), [`zg.md`](zg.md), [`../index.md`](../index.md)

The proxy runs as a Docker container. The image bundles all required backend components — no Antigravity installation needed on the host.

## Quick Start

```bash
# Generate docker-compose.yml + accounts.json template
zg docker-init

# Start the proxy
docker compose up -d

# Verify
curl http://localhost:8741/health
```

## Docker Compose

The `zg docker-init` command generates a ready-to-use `docker-compose.yml`:

```yaml
services:
  zerogravity:
    container_name: zerogravity
    image: ghcr.io/nikketryhard/zerogravity:latest
    restart: unless-stopped
    ports:
      - "8741:8741"
      - "443:443"
    volumes:
      - ./accounts.json:/root/.config/zerogravity/accounts.json
      - ./aliases.json:/root/.config/zerogravity/aliases.json
    environment:
      - ZEROGRAVITY_API_KEY=${ZEROGRAVITY_API_KEY:-}
      - ZEROGRAVITY_OS=${ZEROGRAVITY_OS:-}
      - ZEROGRAVITY_IDE_VERSION=${ZEROGRAVITY_IDE_VERSION:-}
      - ZEROGRAVITY_DEVICE_FINGERPRINT=${ZEROGRAVITY_DEVICE_FINGERPRINT:-}
      - RUST_LOG=info
```

> To use environment variables for accounts instead of a volume mount, remove the `volumes` section from your `docker-compose.yml` and update the `environment` section to include `ZEROGRAVITY_ACCOUNTS`:
> ```yaml
> environment:
>   - ZEROGRAVITY_ACCOUNTS=user1@gmail.com:1//token1,user2@gmail.com:1//token2
>   - ZEROGRAVITY_API_KEY=${ZEROGRAVITY_API_KEY:-}
>   - ZEROGRAVITY_OS=${ZEROGRAVITY_OS:-}
>   - ZEROGRAVITY_IDE_VERSION=${ZEROGRAVITY_IDE_VERSION:-}
>   - ZEROGRAVITY_DEVICE_FINGERPRINT=${ZEROGRAVITY_DEVICE_FINGERPRINT:-}
>   - RUST_LOG=info
> ```
> Comma-separate multiple accounts for automatic rotation on rate limit.

## Docker Run (Alternative)

**With accounts.json:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 \
  -v ./accounts.json:/root/.config/zerogravity/accounts.json \
  ghcr.io/nikketryhard/zerogravity:latest
```

**With env var (single account):**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 \
  -e ZEROGRAVITY_ACCOUNTS="user@gmail.com:1//refresh_token" \
  ghcr.io/nikketryhard/zerogravity:latest
```

**With env var (multiple accounts — comma-separated, auto-rotates on rate limit):**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 \
  -e ZEROGRAVITY_ACCOUNTS="user1@gmail.com:1//token1,user2@gmail.com:1//token2" \
  ghcr.io/nikketryhard/zerogravity:latest
```

## Volumes

| Host Path         | Container Path                               | Purpose                          |
| ----------------- | -------------------------------------------- | -------------------------------- |
| `./accounts.json` | `/root/.config/zerogravity/accounts.json` | Multi-account rotation (primary) |
| `./aliases.json`  | `/root/.config/zerogravity/aliases.json:ro`  | Custom model name aliases        |

## Environment Variables

| Variable                      | Default                 | Description                                          | Example                     |
| ----------------------------- | ----------------------- | ---------------------------------------------------- | --------------------------- |
| `ZEROGRAVITY_ACCOUNTS`        | —                       | Inline accounts — `email:refresh_token`, comma-separated for multiple | `user1@gmail.com:1//0abc...,user2@gmail.com:1//0xyz...` |
| `ZEROGRAVITY_TOKEN`           | —                       | Single OAuth access token — expires in 60min         | `ya29.a0ARrdaM...`          |
| `ZEROGRAVITY_API_KEY`         | —                       | Protect proxy from unauthorized access               | `my-secret-key`             |
| `ZEROGRAVITY_UPSTREAM_PROXY`  | —                       | Route outbound traffic through a proxy               | `socks5://127.0.0.1:1080`   |
| `ZEROGRAVITY_HTTP_PROXY`      | —                       | Pass HTTP/HTTPS corporate proxy settings to the backend child process | `http://proxy.internal:8080` |
| `ZEROGRAVITY_LS_PATH`         | Auto-detected           | Path to backend binary (set automatically in Docker) | `/usr/local/bin/language_server_linux_x64` |
| `ZEROGRAVITY_CONFIG_DIR`      | `~/.config/zerogravity` | Config directory                                     | `/etc/zerogravity`          |
| `ZEROGRAVITY_DATA_DIR`        | `/tmp/.agcache`         | Backend data directory                               | `/var/lib/zerogravity`      |
| `ZEROGRAVITY_APP_ROOT`        | Auto-detected           | Antigravity app root directory                       | `/opt/antigravity`          |
| `ZEROGRAVITY_STATE_DB`        | Auto-detected           | Path to Antigravity's state database                 | `/path/to/state.vscdb`      |
| `ZEROGRAVITY_LS_USER`         | `zerogravity-ls`        | System user for process isolation (Linux)            | `nobody`                    |
| `ZEROGRAVITY_MACHINE_ID_PATH` | Auto-detected           | Path to Antigravity's machine ID file                | `/path/to/machineid`        |
| `ZEROGRAVITY_OS`              | Auto-detected           | Override reported OS label (`Linux`, `macOS`, `Windows`) | `Windows`                 |
| `ZEROGRAVITY_IDE_VERSION`     | Auto-detected           | Preferred override for reported IDE version          | `1.19.4`                    |
| `ZEROGRAVITY_CLIENT_VERSION`  | Auto-detected           | Override the client version string                   | `1.15.8`                    |
| `ZEROGRAVITY_DEVICE_FINGERPRINT` | Auto-detected         | Override reported device fingerprint (UUID required) | `11111111-2222-4333-8444-555555555555` |
| `ZEROGRAVITY_API_BODY_LIMIT_MB` | `32` (clamped `1..100`) | Max request body size in MiB for API routes (`/v1/*`) | `64`                       |
| `SSL_CERT_FILE`               | System default          | Custom CA certificate bundle path                    | `/etc/ssl/certs/ca.pem`     |
| `RUST_LOG`                    | `warn` (runtime default) / `info` (`zg docker-init` template) | Log level | `debug`                     |
| `ZEROGRAVITY_DOH`             | `0` (disabled)          | Enable DNS-over-HTTPS via dns.google (`1` to enable)  | `1`                         |
| `ZEROGRAVITY_STREAM_IDLE_TIMEOUT_SECS` | `120`          | Stream idle timeout in seconds before closing          | `300`                       |

### Customization

| Variable                      | Default   | Description                                                              | Example                                |
| ----------------------------- | --------- | ------------------------------------------------------------------------ | -------------------------------------- |
| `ZEROGRAVITY_QUOTA_CAP`       | `0.2`     | Per-account quota usage cap (0.0–1.0), triggers rotation. `0` to disable | `0.5`                                  |
| `ZEROGRAVITY_SYSTEM_MODE`     | `stealth` | `stealth` = keep backend prompt; `minimal` = replace entirely            | `minimal`                              |
| `ZEROGRAVITY_SENSITIVE_WORDS` | built-in  | Comma-separated client names to obfuscate, or `none` to disable          | `Cursor,Windsurf`                      |
| `ZEROGRAVITY_MODEL_ALIASES`   | —         | Map custom model names to internal models                                | `gpt-4o:gemini-3-flash,gpt-4:opus-4.6` |
| `ZEROGRAVITY_DISPATCH_HOOKS` | `false`   | Enable dispatch timing diagnostics (1/true/on to enable)                 | `true`                                 |

### Request Queue

Serializes generation requests to prevent thundering-herd failures when multiple clients hit the proxy simultaneously.

| Variable                        | Default  | Description                                                | Example  |
| ------------------------------- | -------- | ---------------------------------------------------------- | -------- |
| `ZEROGRAVITY_QUEUE_ENABLED`     | `true`   | Set to `false`, `0`, or `no` to disable the queue entirely | `false`  |
| `ZEROGRAVITY_QUEUE_CONCURRENCY` | `2`      | Max concurrent requests to Google                          | `4`      |
| `ZEROGRAVITY_QUEUE_INTERVAL_MS` | `0`      | Anti-burst gap between consecutive requests (ms)           | `500`    |
| `ZEROGRAVITY_QUEUE_TIMEOUT_MS`  | `600000` | Max wait time in queue before HTTP 408                     | `300000` |
| `ZEROGRAVITY_QUEUE_MAX_SIZE`    | `50`     | Max queue depth; excess requests get HTTP 503              | `100`    |

## Updating

```bash
docker compose pull
docker compose up -d
```
