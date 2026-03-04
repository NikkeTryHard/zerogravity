# Public Documentation

This section is user-facing and should stay concise, stable, and release-ready.

## Canonical Docs

- [`index.md`](index.md) — Documentation index
- [`docker.md`](docker.md) — Deployment and runtime environment
- [`vps.md`](vps.md) — Secure remote VPS deployment baseline
- [`api.md`](api.md) — Endpoints, request examples, auth, monitoring
- [`zg.md`](zg.md) — `zg` CLI command reference

## Scope Rules

- Keep implementation internals in `docs/` root internal docs, not in `docs/pub/`.
- Keep endpoint, command, and env-var details in these docs (not duplicated elsewhere).
