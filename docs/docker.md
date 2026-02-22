# Docker Guide

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
    image: ghcr.io/nikketryhard/zerogravity:latest
    restart: unless-stopped
    ports:
      - "8741:8741"
      - "443:443"
    volumes:
      - ./accounts.json:/root/.config/zerogravity/accounts.json:ro
    environment:
      - ZEROGRAVITY_API_KEY=${ZEROGRAVITY_API_KEY:-}
      - RUST_LOG=info
```

## Docker Run (Alternative)

**With accounts.json:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 \
  -v ./accounts.json:/root/.config/zerogravity/accounts.json:ro \
  ghcr.io/nikketryhard/zerogravity:latest
```

**With env var:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 \
  -e ZEROGRAVITY_ACCOUNTS="user@gmail.com:1//refresh_token" \
  ghcr.io/nikketryhard/zerogravity:latest
```

## Volumes

| Host Path         | Container Path                               | Purpose                          |
| ----------------- | -------------------------------------------- | -------------------------------- |
| `./accounts.json` | `/root/.config/zerogravity/accounts.json:ro` | Multi-account rotation (primary) |

## Environment Variables

| Variable                      | Default                 | Description                                                                   |
| ----------------------------- | ----------------------- | ----------------------------------------------------------------------------- |
| `ZEROGRAVITY_ACCOUNTS`        | —                       | Inline accounts: `email1:1//token1,email2:1//token2`                          |
| `ZEROGRAVITY_TOKEN`           | —                       | Single OAuth access token (`ya29.xxx`) — expires in 60min                     |
| `ZEROGRAVITY_API_KEY`         | —                       | Protect proxy from unauthorized access. Comma-separated for multiple keys     |
| `ZEROGRAVITY_UPSTREAM_PROXY`  | —                       | Route outbound traffic through a proxy (`http://`, `socks5://`, `socks5h://`) |
| `ZEROGRAVITY_LS_PATH`         | Auto-detected           | Path to backend binary (set automatically in Docker)                          |
| `ZEROGRAVITY_CONFIG_DIR`      | `~/.config/zerogravity` | Config directory                                                              |
| `ZEROGRAVITY_DATA_DIR`        | `/tmp/.agcache`         | Backend data directory                                                        |
| `ZEROGRAVITY_APP_ROOT`        | Auto-detected           | Antigravity app root directory                                                |
| `ZEROGRAVITY_STATE_DB`        | Auto-detected           | Path to Antigravity's state database (for token extraction)                   |
| `ZEROGRAVITY_LS_USER`         | `zerogravity-ls`        | System user for process isolation (Linux)                                     |
| `ZEROGRAVITY_MACHINE_ID_PATH` | Auto-detected           | Path to Antigravity's machine ID file                                         |
| `ZEROGRAVITY_CLIENT_VERSION`  | Auto-detected           | Override the client version string                                            |
| `ZEROGRAVITY_MAX_RETRY_DELAY` | Internal default        | Max retry delay in seconds on rate limit errors                               |
| `SSL_CERT_FILE`               | System default          | Custom CA certificate bundle path                                             |
| `RUST_LOG`                    | `info`                  | Log level (`debug`, `info`, `warn`, `error`)                                  |

### Customization

| Variable                      | Default   | Description                                                                         |
| ----------------------------- | --------- | ----------------------------------------------------------------------------------- |
| `ZEROGRAVITY_QUOTA_CAP`       | `0.2`     | Per-account quota usage cap (0.0–1.0), triggers rotation. `0` to disable            |
| `ZEROGRAVITY_SYSTEM_MODE`     | `stealth` | `stealth` = keep backend prompt, inject user override; `minimal` = replace entirely |
| `ZEROGRAVITY_SENSITIVE_WORDS` | built-in  | Comma-separated client names to obfuscate, or `none` to disable                     |

### Request Queue

Serializes generation requests to prevent thundering-herd failures when multiple clients hit the proxy simultaneously.

| Variable                        | Default  | Description                                                |
| ------------------------------- | -------- | ---------------------------------------------------------- |
| `ZEROGRAVITY_QUEUE_ENABLED`     | `true`   | Set to `false`, `0`, or `no` to disable the queue entirely |
| `ZEROGRAVITY_QUEUE_CONCURRENCY` | `2`      | Max concurrent requests to Google                          |
| `ZEROGRAVITY_QUEUE_INTERVAL_MS` | `300`    | Anti-burst gap between consecutive requests (ms)           |
| `ZEROGRAVITY_QUEUE_TIMEOUT_MS`  | `600000` | Max wait time in queue before HTTP 408                     |
| `ZEROGRAVITY_QUEUE_MAX_SIZE`    | `50`     | Max queue depth; excess requests get HTTP 503              |

## Updating

```bash
docker compose pull
docker compose up -d
```
