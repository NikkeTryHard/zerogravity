# `zg` CLI Reference

- **Status**: Active
- **Last validated**: 2026-03-03
- **Related docs**: [`README.md`](README.md), [`docker.md`](docker.md), [`api.md`](api.md), [`../index.md`](../index.md)

`zg` is a standalone CLI tool that works on **any OS** (Linux, macOS, Windows). The proxy itself runs on Linux/Docker only.

## Installation

Download the latest binary from the [releases page](https://github.com/NikkeTryHard/zerogravity/releases) for your platform, or use:

```bash
zg update
```

## Standalone Commands

These work on any OS without a running proxy.

| Command                      | Description                                           |
| ---------------------------- | ----------------------------------------------------- |
| `zg init`                    | First-run setup wizard (token, PATH, client hints)    |
| `zg extract`                 | Extract account from Antigravity → accounts.json      |
| `zg import <file>`           | Import accounts from Antigravity Manager export       |
| `zg accounts`                 | List stored accounts                                  |
| `zg accounts set <email>`    | Set active account                                    |
| `zg accounts remove <email>` | Remove stored account                                 |
| `zg accounts disable <email>` | Exclude account from rotation                        |
| `zg accounts enable <email>` | Re-enable account for rotation                        |
| `zg token`                   | Show OAuth tokens (access + refresh) from Antigravity |
| `zg fingerprint`             | Print device-fingerprint + IDE version env hints      |
| `zg docker-init`             | Generate docker-compose.yml + accounts.json template  |
| `zg rebuild`                 | Rebuild host binary + Docker image and restart daemon |
| `zg update`                  | Download latest zg binary from GitHub                 |

### Model Aliases

| Command                               | Description                    |
| ------------------------------------- | ------------------------------ |
| `zg alias`                            | List configured model aliases  |
| `zg alias set <custom-name> <target>` | Create or update a model alias |
| `zg alias remove <custom-name>`       | Remove a model alias           |

Aliases are stored in `aliases.json` in the config directory. Restart the daemon after changes.

## Daemon Commands

Most of these require a running proxy (Linux / Docker). `zg status` can run
without a live proxy and reports reachability/status details.

| Command            | Description                                        |
| ------------------ | -------------------------------------------------- |
| `zg start`         | Start the proxy daemon                             |
| `zg stop`          | Stop the proxy daemon                              |
| `zg restart`       | Stop + start (no build/download)                   |
| `zg status`        | Version, endpoints, quota, usage, and update check |
| `zg test [msg]`    | Quick test request (gemini-3.1-pro)                |
| `zg health`        | Health check                                       |
| `zg smoke`         | Run comprehensive smoke tests (all endpoints)      |
| `zg smoke --quick` | Quick smoke test (skip streaming/tools)            |

### Logs

| Command              | Description                    |
| -------------------- | ------------------------------ |
| `zg logs [N]`        | Show last N lines (default 30) |
| `zg logs-follow [N]` | Tail last N lines + follow     |
| `zg logs-all`        | Full log dump                  |

### Traces

| Command           | Description                |
| ----------------- | -------------------------- |
| `zg trace`        | Show latest trace summary  |
| `zg trace ls`     | List last 10 traces        |
| `zg trace dir`    | Print trace base directory |
| `zg trace errors` | Show today's error traces  |

Supported subcommands are exactly: `ls`, `dir`, `errors`.

### Diagnostics

| Command                  | Description                                        |
| ------------------------ | -------------------------------------------------- |
| `zg report`              | Generate bounded diagnostic snapshot for bug reports |
| `zg report <id>`         | Bundle a specific trace into a shareable `.tar.gz` |
| `zg replay <file>`       | Re-send a bundled trace to the local proxy         |
| `zg replay --raw <file>` | Send modified request through MITM bypass (no translation) |

## Environment Overrides

| Variable           | Scope | Description |
| ------------------ | ----- | ----------- |
| `PROXY_PORT`       | CLI   | Overrides the target `http://localhost:<port>` used by HTTP-based CLI commands (`zg status`, `zg test`, `zg health`, `zg smoke`, etc.). |
| `ZEROGRAVITY_SRC`  | Dev CLI | Overrides source directory discovery for `zg rebuild` in source-based workflows. |
| `ZEROGRAVITY_OS`   | Runtime | Override reported OS label for metadata/header alignment (`Linux`, `macOS`, `Windows`). |
| `ZEROGRAVITY_IDE_VERSION` | Runtime | Override reported IDE version (preferred over `ZEROGRAVITY_CLIENT_VERSION`). |
| `ZEROGRAVITY_DEVICE_FINGERPRINT` | Runtime | Override reported device fingerprint (UUID format required). |
| `ZEROGRAVITY_DISPATCH_HOOKS` | Runtime | Enable dispatch timing diagnostics (values: 1, true, on). |
