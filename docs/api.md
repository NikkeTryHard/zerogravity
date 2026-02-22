# API Reference

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

Returns the list of available models and their aliases.

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

### Account Rotation

When running with 2+ accounts, the proxy **automatically rotates** to the next account when:

- Google returns `RESOURCE_EXHAUSTED` (429) — after 3 consecutive failures
- Google returns `PERMISSION_DENIED` (403) — **immediate** rotation (no consecutive threshold)

The rotation:

- Waits a short cooldown (5–10s with jitter)
- Refreshes the next account's access token via OAuth
- Restarts the backend to get a clean session
- Clears all rate limiter state

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

Returns token counts for the current session.

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

> **Note:** If `ZEROGRAVITY_API_KEY` is not set, no authentication is enforced (backward-compatible). `/health` and `/` are always public.

## All Endpoints

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
