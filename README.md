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
  OpenAI, Anthropic, and Gemini-compatible proxy for Google's Antigravity.
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
| `opus-4.5`            | Claude Opus 4.5 (Thinking)   | —                   |
| `gemini-3.1-pro`      | Gemini 3.1 Pro (High)        | Default 3.1 tier    |
| `gemini-3.1-pro-high` | Gemini 3.1 Pro (High)        | Alias               |
| `gemini-3.1-pro-low`  | Gemini 3.1 Pro (Low)         | —                   |
| `gemini-3-pro`        | Gemini 3 Pro (High)          | Default Pro tier    |
| `gemini-3-pro-high`   | Gemini 3 Pro (High)          | Alias               |
| `gemini-3-pro-low`    | Gemini 3 Pro (Low)           | —                   |
| `gemini-3-flash`      | Gemini 3 Flash               | Recommended for dev |

## Quick Start

```bash
# First-run setup (auto-detects token, configures PATH)
zg init

# Start the proxy daemon
zg start

# Update both zerogravity and zg to the latest release
zg update

# Check status (version, endpoints, quota, usage)
zg status
```

## Authentication

The proxy needs an OAuth token:

1. **Env var**: `ZEROGRAVITY_TOKEN=ya29.xxx`
2. **Token file**: `~/.config/zerogravity/token`
3. **Runtime**: `curl -X POST http://localhost:8741/v1/token -d '{ "token": "ya29.xxx" }'`

> **Docker users:** When you set a token via `/v1/token`, it's automatically pushed to the backend within 5 seconds — no container restart needed.

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

<details>
<summary>How to get the token</summary>

1. Open Antigravity → **Help** > **Toggle Developer Tools**
2. Go to the **Network** tab
3. Send any prompt
4. Find a request to `generativelanguage.googleapis.com`
5. Look for the `Authorization: Bearer ya29.xxx` header
6. Copy the token (starts with `ya29.`)

> **Note:** OAuth tokens expire after ~1 hour. If Antigravity is installed on the same machine, auto-refresh works automatically.

</details>

<details>
<summary>Auto-refresh with state.vscdb (recommended for Docker / remote servers)</summary>

If Antigravity is installed on the same machine, token refresh works automatically — no config needed.

For remote servers or Docker containers, copy the `state.vscdb` file from any machine where Antigravity is logged in. This database contains a long-lived **refresh token** that lets the proxy auto-refresh access tokens indefinitely.

#### 1. Find `state.vscdb` on the machine with Antigravity

| OS          | Path                                                                       |
| ----------- | -------------------------------------------------------------------------- |
| **Linux**   | `~/.config/Antigravity/User/globalStorage/state.vscdb`                     |
| **macOS**   | `~/Library/Application Support/Antigravity/User/globalStorage/state.vscdb` |
| **Windows** | `%APPDATA%\Antigravity\User\globalStorage\state.vscdb`                     |

#### 2. Copy to your server / Docker host

Just the single `state.vscdb` file — no other files needed.

#### 3. Mount and configure

**Docker (recommended — mount entire Antigravity config dir):**

If you copy the entire Antigravity config dir structure, the proxy auto-detects `state.vscdb` at the default path — no env vars needed:

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -v /path/to/Antigravity:/root/.config/Antigravity:ro \
  ghcr.io/nikketryhard/zerogravity:latest
```

**Docker (manual path — single file mount):**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -v /path/to/state.vscdb:/authfile/state.vscdb:ro \
  -e ZEROGRAVITY_STATE_DB=/authfile/state.vscdb \
  ghcr.io/nikketryhard/zerogravity:latest
```

**Native (no Docker):**

If Antigravity is installed on the same machine, it works automatically. Otherwise:

```bash
ZEROGRAVITY_STATE_DB=/path/to/state.vscdb ./zerogravity --headless
```

> **Note:** This is a one-time copy. The refresh token inside `state.vscdb` is long-lived — the proxy automatically uses it to obtain fresh access tokens. You only need to re-copy if you log out of Antigravity on the source machine.

</details>

## Setup

### Download Binary

```bash
# x86_64
curl -fsSL https://github.com/NikkeTryHard/zerogravity/releases/latest/download/zerogravity-linux-x86_64 -o zerogravity
chmod +x zerogravity

# ARM64
curl -fsSL https://github.com/NikkeTryHard/zerogravity/releases/latest/download/zerogravity-linux-arm64 -o zerogravity
chmod +x zerogravity
```

### Linux

```bash
./scripts/setup-linux.sh
zg start
```

### macOS

```bash
./scripts/setup-macos.sh
zg start
```

### Windows

```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
.\zerogravity.exe
```

### Docker

**Recommended (auto-refresh via Antigravity config mount):**

If Antigravity is installed on the host, mount its config dir and the proxy auto-detects `state.vscdb` for token refresh — no env vars needed:

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -v $HOME/.config/Antigravity:/root/.config/Antigravity:ro \
  ghcr.io/nikketryhard/zerogravity:latest
```

**With manual token:**

```bash
docker run -d --name zerogravity \
  -p 8741:8741 -p 8742:8742 \
  -e ZEROGRAVITY_TOKEN=ya29.xxx \
  -e ZEROGRAVITY_API_KEY=your-secret-key \
  ghcr.io/nikketryhard/zerogravity:latest
```

**Docker Compose (auto-generated):**

```bash
# Generate docker-compose.yml + .env with auto-detected token
zg docker-init
docker compose up -d
```

**Docker Compose (manual):**

```bash
docker compose up -d
```

> **Note:** The Docker image bundles all required backend components — no Antigravity installation needed on the host. If Antigravity IS installed, mounting the config dir gives you automatic token refresh with no manual token management.

## Endpoints

| Method     | Path                              | Description                           |
| ---------- | --------------------------------- | ------------------------------------- |
| `POST`     | `/v1/responses`                   | Responses API (sync + streaming)      |
| `POST`     | `/v1/chat/completions`            | Chat Completions API (OpenAI compat)  |
| `POST`     | `/v1/messages`                    | Messages API (Anthropic compat)       |
| `POST`     | `/v1beta/models/{model}:{action}` | Official Gemini v1beta routes         |
| `GET/POST` | `/v1/search`                      | Web Search via Google grounding (WIP) |
| `GET`      | `/v1/models`                      | List available models                 |
| `POST`     | `/v1/token`                       | Set OAuth token at runtime            |
| `GET`      | `/v1/usage`                       | Proxy token usage                     |
| `GET`      | `/v1/quota`                       | Quota and rate limits                 |
| `GET`      | `/health`                         | Health check                          |

## `zg` Commands

### Setup

| Command          | Description                                            |
| ---------------- | ------------------------------------------------------ |
| `zg init`        | First-run setup wizard (token, PATH, client hints)     |
| `zg token`       | Extract OAuth token from local Antigravity state.vscdb |
| `zg docker-init` | Generate docker-compose.yml + .env in current dir      |

### Service

| Command              | Description                                               |
| -------------------- | --------------------------------------------------------- |
| `zg start`           | Start the proxy daemon                                    |
| `zg stop`            | Stop the proxy daemon                                     |
| `zg restart`         | Stop + start (no build/download)                          |
| `zg update`          | Download latest release from GitHub (updates zg + binary) |
| `zg status`          | Version, endpoints, quota, usage, and update check        |
| `zg logs [N]`        | Show last N lines (default 30)                            |
| `zg logs-follow [N]` | Tail last N lines + follow                                |
| `zg logs-all`        | Full log dump                                             |
| `zg test [msg]`      | Quick test request (gemini-3-flash)                       |
| `zg health`          | Health check                                              |
| `zg trace`           | Show latest trace summary                                 |
| `zg trace ls`        | List last 10 traces                                       |
| `zg trace dir`       | Print trace base directory                                |
| `zg trace errors`    | Show today's error traces                                 |

## License

[MIT](LICENSE)
