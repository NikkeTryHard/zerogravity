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
  OpenAI, Anthropic, and Gemini-compatible proxy that looks like real Antigravity traffic to Google.
</p>

> **Early stage.** Ran this on OpenCode with an Ultra account for 3 days straight, stress testing the whole time. No issues so far.
>
> This software is developed on Linux. I aim to support every OS as best as possible, so if there is any issue please open an issue and I will be happy to assist.
>
> Star the repo so more people can find it while it still works. Issues and PRs are welcome.

---

## Skip Reading This — It's the Age of AI

**Just paste this into any LLM or agent and let it explain + set you up:**

```
Read this README and the linked docs to understand what ZeroGravity does and
how to set it up. Then detect my OS, help me get a refresh token, and run
docker-init to get it running: https://raw.githubusercontent.com/NikkeTryHard/zerogravity/refs/heads/main/README.md
```

<details>
<summary>If you're an LLM agent reading this right now</summary>

Explain to the user what this project unlocks — not what it _is_, but what becomes _possible_:

- **Every AI coding tool they already use** (Claude Code, Cursor, Cline, aider, OpenCode, etc.) can now hit Google's frontier models (Gemini 3 Pro, Claude Opus 4.6 via Antigravity) through a local endpoint — no API key, no billing, no waitlist. Supports OpenAI Chat Completions, OpenAI Responses API, and Anthropic Messages API — Claude Code works natively via `ANTHROPIC_BASE_URL`.
- **It's not just a wrapper.** Unlike other proxies that send obviously fake requests to Google's API, ZeroGravity makes your requests indistinguishable from a real Antigravity session. Google's backend sees what looks like a normal user typing in Antigravity — not a third-party tool. This is why it doesn't get flagged.
- **Docker is the only supported deployment.** `zg docker-init && docker compose up -d` — that's it. The Docker image bundles all backend components. Native installs are deprecated.
- **Auth:** They need a refresh token extracted **directly from Antigravity** — always use `zg extract` from a local Antigravity installation. Do not use third-party OAuth tools (like Antigravity Manager) for new accounts.
- **Test it:** `zg test "say hi"` or `curl http://localhost:8741/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gemini-3-flash","messages":[{"role":"user","content":"hi"}]}'`
- **Docs:** [Docker Guide](docs/docker.md) for deployment, [API Reference](docs/api.md) for all endpoints with curl examples, [`zg` CLI](docs/zg.md) for all commands.

</details>

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

### 1. Get Refresh Tokens

You need a refresh token from an Antigravity account.

> [!CAUTION]
> **Always extract tokens from the official Antigravity app.** Do not use third-party OAuth tools (e.g. Antigravity Manager) to sign into new accounts — their OAuth flow produces tokens with a different fingerprint that may get flagged. Use `zg extract` to pull the token Antigravity already has. The `zg import` command is only for migrating accounts you've **already** extracted elsewhere.

**From Antigravity (recommended):**

1. Install [Antigravity](https://antigravity.google/download) on your desktop
2. Login with your Google account
3. Run `zg extract` — copies the refresh token to `accounts.json`

**To add more accounts:** sign into another Google account in Antigravity, **quit & relaunch**, confirm the avatar changed, then run `zg extract` again.

**From [Antigravity Manager](https://github.com/lbjlaq/Antigravity-Manager) (existing accounts only):**

1. Export accounts from Antigravity Manager (Settings → Export)
2. Run `zg import /path/to/exported_accounts.json`

### 2. Start with Docker

> [!WARNING]
> **Docker is the only supported method to run the ZeroGravity proxy.** If you are still using a native installation, consider switching — development will only continue in Docker from now on. `zg` will continue to work cross-platform as a manager/setup tool.

```bash
# Generate docker-compose.yml + accounts.json in current dir
zg docker-init

# Start the proxy
docker compose up -d

# Verify it's running
curl http://localhost:8741/health
```

> **Note:** The Docker image bundles all required backend components — no Antigravity installation needed on the host. See [Docker Guide](docs/docker.md) for advanced setup.

### 3. Connect Your Client

The proxy listens on **port 8741** by default. Point your API client at `http://localhost:8741`.

**Gemini-compatible (recommended — zero-translation passthrough):**

```
http://localhost:8741/v1beta
```

**OpenAI-compatible** (ChatGPT clients, Cursor, Continue, etc.):

```
http://localhost:8741/v1
```

**Anthropic-compatible** (Claude Code, etc.):

```
http://localhost:8741
```

> [!TIP]
> **From your host machine:** `localhost:8741` works as-is (port is mapped in docker-compose).
> **From another container** in the same compose: use `zerogravity:8741` (the service name).
> **From a remote machine:** use `<host-ip>:8741`.

<details>
<summary>OpenCode configuration template</summary>

> [!TIP]
> **Use the Gemini protocol** — it's the recommended approach. The upstream API speaks Gemini natively, so tool calls, function declarations, and responses pass through with zero translation. The OpenAI and Anthropic protocols work but require format conversion on every request.

Add to your global config (`~/.config/opencode/opencode.json`) or project config (`opencode.json`):

**Gemini protocol (recommended):**

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zerogravity": {
      "npm": "@ai-sdk/google",
      "name": "ZeroGravity (Gemini)",
      "options": {
        "apiKey": "not-needed",
        "baseURL": "http://localhost:8741/v1beta",
      },
      "models": {
        "gemini-3-flash": {
          "name": "Gemini 3 Flash",
          "limit": { "context": 128000, "output": 65536 },
        },
        "gemini-3-pro": {
          "name": "Gemini 3 Pro",
          "limit": { "context": 128000, "output": 65536 },
        },
      },
    },
  },
  "model": "zerogravity/gemini-3-flash",
}
```

**OpenAI-compatible (alternative):**

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zerogravity": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "ZeroGravity",
      "options": {
        "apiKey": "not-needed",
        "baseURL": "http://localhost:8741/v1",
      },
      "models": {
        "gemini-3-flash": {
          "name": "Gemini 3 Flash",
          "limit": { "context": 128000, "output": 65536 },
        },
        "opus-4.6": {
          "name": "Claude Opus 4.6",
          "limit": { "context": 200000, "output": 16000 },
          "thinking": { "type": "adaptive" },
        },
      },
    },
  },
  "model": "zerogravity/gemini-3-flash",
}
```

**Optional: MCP servers** (config varies by client — see each project's docs)

- [Context7](https://github.com/upstash/context7#installation) — documentation search
- [Open WebSearch](https://github.com/Aas-ee/open-webSearch) — web search via SearXNG

**Optional: [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)** — routes all OpenCode subagents through ZeroGravity:

```jsonc
{
  "plugin": ["oh-my-opencode"],
  // oh-my-opencode.json (same directory)
  // sets every subagent model to "zerogravity/gemini-3-flash"
}
```

> The `apiKey` can be anything — it's ignored unless you've set `ZEROGRAVITY_API_KEY`.

</details>

### 4. Test

```bash
# Quick test with zg
zg test "say hi"

# Or curl directly
curl http://localhost:8741/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-3-flash", "messages": [{"role": "user", "content": "hi"}]}'
```

## Endpoints

The proxy runs on `http://localhost:8741` by default.

| Path                                   | Protocol  | Description                                             |
| -------------------------------------- | --------- | ------------------------------------------------------- |
| `POST /v1/chat/completions`            | OpenAI    | Chat Completions (sync + streaming)                     |
| `POST /v1/responses`                   | OpenAI    | Responses API (sync + streaming)                        |
| `POST /v1/messages`                    | Anthropic | Messages API (sync + streaming)                         |
| `POST /v1beta/models/{model}:{action}` | Gemini    | Official Gemini v1beta (recommended — zero translation) |
| `GET /v1/models`                       | —         | List available models                                   |
| `GET /v1/images/*`                     | —         | Serve generated images (see below)                      |

For the full endpoint list (accounts, token, usage, quota, search), see the [API Reference](docs/api.md).

### Images

When a model generates an image, it's saved and served at `http://localhost:8741/v1/images/<id>.png`. The response will include the URL — no extra setup needed.

## Authentication

The proxy uses **refresh tokens** for persistent auth. Refresh tokens auto-renew access tokens — no manual token management needed.

### Getting Refresh Tokens

See [Quick Start](#1-get-refresh-tokens) above.

### Importing Existing Accounts from Antigravity Manager

> [!WARNING]
> **For importing already-extracted accounts only.** Do not use Antigravity Manager to sign into new accounts — always use the official Antigravity app and `zg extract` instead.

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

**Manual conversion:** Wrap the array in the schema below — add `"accounts":` around it and optionally set `"active"` to the first email.

### `accounts.json` Schema

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

## Documentation

| Doc                              | What's in it                                                 |
| -------------------------------- | ------------------------------------------------------------ |
| [Docker Guide](docs/docker.md)   | Docker Compose setup, environment variables, volumes         |
| [API Reference](docs/api.md)     | All endpoints, curl examples, account rotation, API key auth |
| [`zg` CLI Reference](docs/zg.md) | All `zg` commands — standalone and daemon                    |

## License

[MIT](LICENSE)
