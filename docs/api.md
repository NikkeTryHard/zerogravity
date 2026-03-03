# API Reference

- **Status**: Active
- **Last validated**: 2026-03-03
- **Related docs**: [`README.md`](README.md), [`docker.md`](docker.md), [`zg.md`](zg.md), [`../index.md`](../index.md)

The proxy runs on `http://localhost:8741` by default.

## Protocol Endpoints

### OpenAI-compatible

**Chat Completions:**

```bash
curl http://localhost:8741/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-3-flash",
    "messages": [{"role": "user", "content": "hello"}],
    "stream": true
  }'
```

**Responses API:**

```bash
curl http://localhost:8741/v1/responses \
  -H "Content-Type: application/json" \
  -d '{
    "model": "opus-4.6",
    "input": "explain quantum computing"
  }'
```

### Anthropic-compatible

**Messages API:**

```bash
curl http://localhost:8741/v1/messages \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "opus-4.6",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "hello"}]
  }'
```

### Gemini-compatible

```bash
curl http://localhost:8741/v1beta/models/gemini-3-flash:generateContent \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts": [{"text": "hello"}]}]
  }'
```

## Models

```bash
curl http://localhost:8741/v1/models
```

Returns the list of available built-in models.

## Model Aliases

Map custom model names to any built-in model. Requests using an alias are transparently rewritten to the target model.

**Three ways to configure:**

1. **CLI** (recommended): `zg alias set gpt-4o gemini-3-flash`
2. **JSON file**: `aliases.json` in the config directory (same location as `accounts.json`)
3. **Env var**: `ZEROGRAVITY_MODEL_ALIASES=gpt-4o:gemini-3-flash,gpt-4:opus-4.6`

JSON file takes precedence, env var overrides. Restart the daemon after changes.

## Images

When a model generates an image, it is automatically saved and served:

```
GET http://localhost:8741/v1/images/<id>.png
```

Image URLs are included in model responses — no configuration needed.

## Search (WIP)

```bash
curl http://localhost:8741/v1/search?q=latest+news
```

Web search powered by Google grounding. Still work in progress.

## Account Management

### Add Account

```bash
curl -X POST http://localhost:8741/v1/accounts \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com", "refresh_token": "1//0fXXX"}'
```

### List Accounts

```bash
curl http://localhost:8741/v1/accounts
```

### Remove Account

```bash
curl -X DELETE http://localhost:8741/v1/accounts \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com"}'
```

### Set Active Account (Runtime)

Switches the active account immediately without restarting the proxy process manually.

```bash
curl -X POST http://localhost:8741/v1/accounts/set_active \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com"}'
```

### Account Status

```bash
curl http://localhost:8741/v1/accounts/status
```

Returns per-account details including email, active flag, and quota usage breakdown.

### Account Rotation

When running with 2+ accounts, the proxy **automatically rotates** to the next account when:

- Google returns `RESOURCE_EXHAUSTED` (429) — after 3 consecutive failures
- Google returns `PERMISSION_DENIED` (403) — **immediate** rotation (no consecutive threshold)

The rotation:

- Waits a short cooldown (5–10s with jitter)
- Refreshes the next account's access token via OAuth
- Restarts the backend to get a clean session
- Resets cooldown windows while preserving exhaustion counters

Use `--quota-cap 0.2` (default) or set `ZEROGRAVITY_QUOTA_CAP=0.2` to rotate proactively when any model exceeds 80% usage. When all accounts are exhausted, the proxy parks and waits for quota to reset. Set to `0` to disable proactive rotation.

## Token Management

### Set Token at Runtime

```bash
curl -X POST http://localhost:8741/v1/token \
  -H "Content-Type: application/json" \
  -d '{"token": "ya29.xxx"}'
```

> **Note:** Access tokens expire in ~60 minutes. Use refresh tokens via `accounts.json` or `POST /v1/accounts` instead.

## Monitoring

### Usage

```bash
curl http://localhost:8741/v1/usage
```

Returns token counts persisted by the proxy, including stats restored across restarts.

### Quota

```bash
curl http://localhost:8741/v1/quota
```

Returns per-model quota limits and current usage from the backend.

### Health Check

```bash
curl http://localhost:8741/health
```

Returns `200 OK` when the proxy is running.

### Raw Replay

```bash
curl -X POST http://localhost:8741/v1/replay/raw \
  -H "Content-Type: application/json" \
  --data-binary @modified_request.json
```

Send a pre-built payload (from a trace's `modified_request.json`) directly through the MITM tunnel, bypassing all request translation. Used for latency diagnostics.

## API Key Protection

Protect the proxy from unauthorized access by setting `ZEROGRAVITY_API_KEY`:

```bash
# Single key
export ZEROGRAVITY_API_KEY="your-secret-key"

# Multiple keys (comma-separated)
export ZEROGRAVITY_API_KEY="key1,key2,key3"
```

Clients must include the key using any of these header formats:

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

# Gemini-style (x-goog-api-key)
curl http://localhost:8741/v1beta/models/gemini-3-flash:generateContent \
  -H "x-goog-api-key: your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "hi"}]}]}'
```

> **Note:** If `ZEROGRAVITY_API_KEY` is not set, no authentication is enforced (backward-compatible). Public compatibility routes include `/health`, `/`, `/api/event_logging/batch`, `/.well-known/{*path}`, and `/v1/images/{*path}`.

## Debug / Testing

### Simulate Account State

Inject fake runtime state for an account to test rotation selection, quota behavior, and error handling without real Google traffic. Requires `ZEROGRAVITY_DEBUG=1` environment variable -- returns 404 when disabled.

```bash
# Mark an account as banned
curl -X POST http://localhost:8741/v1/debug/simulate \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com", "banned": true}'

# Simulate quota exhaustion (triggers rotation on next request)
curl -X POST http://localhost:8741/v1/debug/simulate \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com", "remaining_fraction": 0.0, "cooldown_secs": 3600}'

# Clear a ban and restore quota
curl -X POST http://localhost:8741/v1/debug/simulate \
  -H "Content-Type: application/json" \
  -d '{"email": "user@gmail.com", "banned": false, "remaining_fraction": 1.0}'
```

**Request body:**

| Field                | Type    | Required | Description                                       |
| -------------------- | ------- | -------- | ------------------------------------------------- |
| `email`              | string  | Yes      | Account email to modify                           |
| `banned`             | boolean | No       | Mark account as banned (skipped by rotation)      |
| `restricted`         | boolean | No       | Mark account as restricted (skipped by rotation)  |
| `cooldown_secs`      | integer | No       | Seconds until account is eligible for selection   |
| `remaining_fraction` | float   | No       | Quota remaining (0.0 = exhausted, 1.0 = full)     |

Only provided fields are applied -- omitted fields keep their current value. The response returns the account's current state after the update.

**Enable debug mode:**

```bash
# Docker Compose
environment:
  - ZEROGRAVITY_DEBUG=1

# Or export before starting
export ZEROGRAVITY_DEBUG=1
```

## All Endpoints

| Method     | Path                              | Description                           |
| ---------- | --------------------------------- | ------------------------------------- |
| `POST`     | `/v1/chat/completions`            | Chat Completions API (OpenAI compat)  |
| `POST`     | `/v1/responses`                   | Responses API (sync + streaming)      |
| `POST`     | `/v1/messages`                    | Messages API (Anthropic compat)       |
| `POST`     | `/v1/messages/count_tokens`       | Anthropic token counting endpoint     |
| `POST`     | `/v1beta/models/{model}:{action}` | Official Gemini v1beta routes         |
| `GET`      | `/v1beta/models`                  | List models (Gemini v1beta format)    |
| `GET`      | `/v1beta/models/{model}`          | Get model info (Gemini v1beta format) |
| `GET`      | `/v1/models`                      | List available models                 |
| `GET/POST` | `/v1/search`                      | Web Search via Google grounding (WIP) |
| `POST`     | `/v1/token`                       | Set OAuth token at runtime            |
| `POST`     | `/v1/accounts`                    | Add account (email + refresh_token)   |
| `POST`     | `/v1/accounts/set_active`         | Set active account at runtime          |
| `GET`      | `/v1/accounts`                    | List stored accounts                  |
| `DELETE`   | `/v1/accounts`                    | Remove account by email               |
| `GET`      | `/v1/accounts/status`             | Per-account status with quota usage   |
| `GET`      | `/v1/usage`                       | Proxy token usage                     |
| `GET`      | `/v1/quota`                       | Quota and rate limits                 |
| `GET`      | `/v1/images/*`                    | Serve generated images                |
| `POST`     | `/v1/replay/raw`                  | Send pre-built trace through MITM     |
| `POST`     | `/v1/debug/simulate`              | Inject account state (debug only)     |
| `GET`      | `/health`                         | Health check                          |
| `GET/POST` | `/`                               | Compatibility root (returns status)   |
| `POST`     | `/api/event_logging/batch`        | Compatibility event logging endpoint  |
| `GET/POST` | `/.well-known/{*path}`            | Compatibility well-known endpoint     |

## Behavior Notes

### Default Output Tokens

When a client omits `max_tokens` (Anthropic), `max_completion_tokens` (OpenAI), or `max_output_tokens` (OpenAI Responses), the proxy defaults to **64,000 tokens** -- just below Gemini's 65,536 ceiling. The MITM layer enforces a minimum of 4,096 regardless. This means clients that previously got errors for missing `max_tokens` now receive a sensible default.

### Thinking Budget (Claude Aliases)

Claude aliases (`opus-4.6`, `sonnet-4.6`) are backed by Gemini models. When clients send `budget_tokens` via the Anthropic Messages API, the proxy maps it to Gemini thinking levels:

| budget_tokens | Gemini thinkingLevel |
|---------------|---------------------|
| 0             | disabled            |
| 1 -- 512      | minimal             |
| 513 -- 1024   | low                 |
| 1025 -- 4096  | medium              |
| 4097+         | high                |

Raw integer budgets cause 400 INVALID_ARGUMENT on Gemini 3+ models. The proxy handles this automatically.

### Tool Calling

OpenAI and Anthropic tool/function declarations are translated to Gemini's format. During translation:
- **Constraint hints** (`minLength`, `maxLength`, `pattern`, `format`, `default`, `examples`) are preserved as description text since Gemini strips these JSON Schema keys
- **Nullable properties** are removed from `required` arrays
- **Union types** (e.g. `["string", "array"]`) produce "Accepts: string | array" description hints
- **Non-standard keys** (`strict`, `x-*` prefixed, etc.) are stripped before sending to Gemini

Gemini-native tool declarations (via `/v1beta/`) pass through with zero translation.
