> [!IMPORTANT]
> **Source code has moved to a private repository** for long-term sustainability.
> Binaries, Docker images, and releases will continue to be published here.
>
> **Want access to the source?**
>
> - [Open a Discussion](https://github.com/NikkeTryHard/zerogravity/discussions) on this repo
> - [Join our Telegram](https://t.me/ZeroGravityProxy) and DM me
>
> Read-only access is granted on request.

<p align="center">
  <img src="https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-555?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-MIT-333?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/API-OpenAI%20%7C%20Anthropic%20%7C%20Gemini-666?style=flat-square" alt="API" />
</p>

<h1 align="center">ZeroGravity</h1>

<p align="center">
  <img src="assets/logo.png" alt="ZeroGravity" width="200" />
</p>

<p align="center">
  OpenAI, Anthropic, and Gemini-compatible proxy.
</p>

> **Early stage.** Ran this on OpenCode with an Ultra account for 3 days straight, stress testing the whole time. No issues so far.
>
> This software is developed on Linux. I aim to support every OS as best as possible, so if there is any issue please open an issue and I will be happy to assist.
>
> Star the repo so more people can find it while it still works. Issues and PRs are welcome.

---

## Models

| Name                  | Label                        | Notes               |
| --------------------- | ---------------------------- | ------------------- |
| `opus-4.6`            | Claude Opus 4.6 (Thinking)   | Default model       |
| `sonnet-4.6`          | Claude Sonnet 4.6 (Thinking) | —                   |
| `gemini-3-flash`      | Gemini 3 Flash               | Recommended for dev |
| `gemini-3.1-pro`      | Gemini 3.1 Pro (High)        | Experimental        |
| `gemini-3.1-pro-high` | Gemini 3.1 Pro (High)        | Alias               |
| `gemini-3.1-pro-low`  | Gemini 3.1 Pro (Low)         | Experimental        |

## Quick Start

```bash
# First-run setup (auto-detects token, configures PATH)
zg init

# Start the proxy daemon
zg start

# Quick test
zg test "say hi"

# Check status (version, endpoints, quota, usage)
zg status

# Generate docker-compose.yml + .env (for Docker users)
zg docker-init
docker compose up -d

# Update to the latest release
zg update
```

## Endpoints

| Method     | Path                              | Description                           |
| ---------- | --------------------------------- | ------------------------------------- |
| `POST`     | `/v1/chat/completions`            | Chat Completions API (OpenAI compat)  |
| `POST`     | `/v1/responses`                   | Responses API (sync + streaming)      |
| `POST`     | `/v1/messages`                    | Messages API (Anthropic compat)       |
| `POST`     | `/v1beta/models/{model}:{action}` | Official Gemini v1beta routes         |
| `GET`      | `/v1/models`                      | List available models                 |
| `GET/POST` | `/v1/search`                      | Web Search via Google grounding (WIP) |
| `POST`     | `/v1/token`                       | Set OAuth token at runtime            |
| `POST`     | `/v1/accounts`                    | Add account (email + refresh_token)   |
| `GET`      | `/v1/accounts`                    | List stored accounts                  |
| `DELETE`   | `/v1/accounts`                    | Remove account by email               |
| `GET`      | `/v1/usage`                       | Proxy token usage                     |
| `GET`      | `/v1/quota`                       | Quota and rate limits                 |
| `GET`      | `/v1/images/*`                    | Serve generated images                |
| `GET`      | `/health`                         | Health check                          |

## Setup

### Docker (Recommended)

**With accounts.json for auto-refresh:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -v ./accounts.json:/root/.config/zerogravity/accounts.json:ro \
  ghcr.io/nikketryhard/zerogravity:latest
```

**With env var:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -e ZEROGRAVITY_ACCOUNTS="user@gmail.com:1//refresh_token" \
  ghcr.io/nikketryhard/zerogravity:latest
```

**Docker Compose (auto-generated):**

```bash
zg docker-init
docker compose up -d
```

> **Note:** The Docker image bundles all required backend components — no Antigravity installation needed on the host.

### Native (Not Recommended)

Setup scripts and pre-built binaries exist for Linux, macOS, and Windows but are not actively tested. See `scripts/` and the [releases page](https://github.com/NikkeTryHard/zerogravity/releases) for binaries. Docker is the preferred deployment method.

## Authentication

The proxy uses **refresh tokens** for persistent authentication. Refresh tokens are long-lived and auto-renew access tokens — no manual token management needed.

### Getting Refresh Tokens

1. Install [Antigravity](https://antigravity.google/download) on your desktop
2. Login with your Google account
3. Run `zg extract` — this copies the refresh token to `~/.config/zerogravity/accounts.json`

**To add more accounts:**

1. Open Antigravity and sign in with a different Google account
2. **Quit** Antigravity completely (not just close the window)
3. **Relaunch** Antigravity and confirm the avatar icon changed
4. Run `zg extract` again

### Setting Tokens

| Method                 | Description                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `accounts.json`        | File with refresh tokens — recommended for Docker (mount as volume)                     |
| `ZEROGRAVITY_ACCOUNTS` | Env var: `email1:1//token1,email2:1//token2`                                            |
| `POST /v1/accounts`    | Runtime: `curl -X POST .../v1/accounts -d '{"email":"x@y.z","refresh_token":"1//xxx"}'` |
| `ZEROGRAVITY_TOKEN`    | Single access token (expires in 60min, not recommended)                                 |
| `POST /v1/token`       | Runtime access token injection                                                          |

### Account Rotation

When running with 2+ accounts, the proxy **automatically rotates** to the next account when Google returns `RESOURCE_EXHAUSTED` (429). The rotation:

- Waits a short cooldown (5-10s)
- Refreshes the next account's access token via OAuth
- Restarts the backend to get a clean session
- Clears all rate limiter state

Use `--quota-cap 0.2` (default) to rotate proactively when any model exceeds 80% usage. When all accounts are below the cap, the proxy parks and waits for quota to reset naturally instead of rotating endlessly. Set to `0` to disable.

No manual intervention needed — quota exhaustion is handled transparently.

### API Key Protection (Optional)

Protect the proxy from unauthorized access by setting an API key:

```bash
# Single key
export ZEROGRAVITY_API_KEY="your-secret-key"

# Multiple keys (comma-separated)
export ZEROGRAVITY_API_KEY="key1,key2,key3"
```

Clients must then include the key in requests using either header format:

```bash
# OpenAI-style (Authorization: Bearer)
curl http://localhost:8741/v1/chat/completions \
  -H "Authorization: Bearer your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-3-flash", "messages": [{"role": "user", "content": "hi"}]}'

# Anthropic-style (x-api-key)
curl http://localhost:8741/v1/messages \
  -H "x-api-key: your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "opus-4.6", "max_tokens": 1024, "messages": [{"role": "user", "content": "hi"}]}'
```

> **Note:** If `ZEROGRAVITY_API_KEY` is not set, no API key authentication is enforced (backward-compatible). The `/health` and `/` endpoints are always public.

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

### Request Queue

Serializes generation requests to prevent thundering-herd failures when multiple clients hit the proxy simultaneously.

| Variable                        | Default  | Description                                                |
| ------------------------------- | -------- | ---------------------------------------------------------- |
| `ZEROGRAVITY_QUEUE_ENABLED`     | `true`   | Set to `false`, `0`, or `no` to disable the queue entirely |
| `ZEROGRAVITY_QUEUE_CONCURRENCY` | `1`      | Max concurrent requests to Google                          |
| `ZEROGRAVITY_QUEUE_INTERVAL_MS` | `300`    | Anti-burst gap between consecutive requests (ms)           |
| `ZEROGRAVITY_QUEUE_TIMEOUT_MS`  | `600000` | Max wait time in queue before HTTP 408                     |
| `ZEROGRAVITY_QUEUE_MAX_SIZE`    | `50`     | Max queue depth; excess requests get HTTP 503              |

## Docker Volumes

| Host Path         | Container Path                               | Purpose                          |
| ----------------- | -------------------------------------------- | -------------------------------- |
| `./accounts.json` | `/root/.config/zerogravity/accounts.json:ro` | Multi-account rotation (primary) |

## `zg` Commands

`zg` is a standalone CLI tool that works on **any OS** (Linux, macOS, Windows). The proxy itself runs on Linux / Docker only.

### Standalone (works on any OS, no daemon needed)

| Command                      | Description                                             |
| ---------------------------- | ------------------------------------------------------- |
| `zg extract`                 | Extract account from Antigravity → accounts.json        |
| `zg import <file>`           | Import accounts from Antigravity Manager export         |
| `zg accounts`                | List stored accounts                                    |
| `zg accounts set <email>`    | Set active account                                      |
| `zg accounts remove <email>` | Remove stored account                                   |
| `zg token`                   | Extract OAuth token from local Antigravity installation |
| `zg init`                    | First-run setup wizard (token, PATH, client hints)      |
| `zg docker-init`             | Generate docker-compose.yml + accounts.json template    |
| `zg update`                  | Download latest zg binary from GitHub                   |

### Daemon (requires running proxy — Linux / Docker)

| Command              | Description                                        |
| -------------------- | -------------------------------------------------- |
| `zg start`           | Start the proxy daemon                             |
| `zg stop`            | Stop the proxy daemon                              |
| `zg restart`         | Stop + start (no build/download)                   |
| `zg status`          | Version, endpoints, quota, usage, and update check |
| `zg logs [N]`        | Show last N lines (default 30)                     |
| `zg logs-follow [N]` | Tail last N lines + follow                         |
| `zg logs-all`        | Full log dump                                      |
| `zg test [msg]`      | Quick test request (gemini-3-flash)                |
| `zg health`          | Health check                                       |
| `zg report`          | Generate full diagnostic report for bug reports    |
| `zg report <id>`     | Bundle a specific trace into a shareable `.tar.gz` |
| `zg replay <file>`   | Re-send a bundled trace to the local proxy         |
| `zg trace`           | Show latest trace summary                          |
| `zg trace ls`        | List last 10 traces                                |
| `zg trace dir`       | Print trace base directory                         |
| `zg trace errors`    | Show today's error traces                          |

## `accounts.json` Schema

The proxy reads accounts from `~/.config/zerogravity/accounts.json`:

```json
{
  "accounts": [
    {
      "email": "user@gmail.com",
      "refresh_token": "1//0fXXXXXXXXXX",
      "extracted_at": "2026-02-21T05:08:32Z"
    }
  ],
  "active": "user@gmail.com"
}
```

| Field           | Required | Description                                             |
| --------------- | -------- | ------------------------------------------------------- |
| `email`         | Yes      | Google account email                                    |
| `refresh_token` | Yes      | OAuth refresh token (starts with `1//`)                 |
| `alias`         | No       | Friendly alias for the account                          |
| `extracted_at`  | No       | ISO 8601 timestamp of when the account was added        |
| `active`        | No       | Email of the currently active account (top-level field) |

### Importing from Antigravity Manager

[Antigravity Manager](https://github.com/lbjlaq/Antigravity-Manager) exports accounts as a flat JSON array:

```json
[
  { "email": "user@gmail.com", "refresh_token": "1//0fXXX" },
  { "email": "user2@gmail.com", "refresh_token": "1//0fYYY" }
]
```

**With `zg` (recommended):**

```bash
zg import /path/to/antigravity_accounts.json
```

This auto-detects the format, converts it, and merges into your existing `accounts.json`.

**Manual conversion:** Wrap the array in the schema above — add `"accounts":` around it and optionally set `"active"` to the first email. You can create `accounts.json` by hand without needing `zg` at all.

## License

[MIT](LICENSE)
