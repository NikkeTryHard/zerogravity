# Client Operations Guide

Use this page as the operator-facing source of truth for client-specific behavior through ZeroGravity.

## Claude Code

- **Supported endpoint style:** Anthropic-compatible (`/v1/messages`, optional `/v1/messages/count_tokens`) via `ANTHROPIC_BASE_URL`.
- **Proxy-side transformations that affect UX:**
  - Anthropic request/response shape is translated to/from Gemini-backed upstream calls.
  - `budget_tokens` values are mapped to Gemini thinking levels for Claude aliases (`opus-4.6`, `sonnet-4.6`).
  - Generation requests still pass through global queue controls (`ZEROGRAVITY_QUEUE_*`) and may wait under load.
  - Missing `max_tokens` gets a proxy default (64k, with internal minimum enforcement).
- **Recommended defaults:**
  - Keep models on published aliases (`opus-4.6`, `sonnet-4.6`) instead of ad-hoc names.
  - Set realistic `max_tokens` and keep prompts compact to reduce queue time and context pressure.
  - Keep the default queue enabled for shared/team usage.
- **Anti-patterns:**
  - Disabling queue in multi-client environments.
  - Sending giant attachments/history blobs near API body limits.
  - Treating `budget_tokens` as exact output control (it is a thinking-level signal after mapping).
- **Troubleshooting checklist (429/503/capacity/context):**
  - Confirm `/health` is healthy and account status is not exhausted.
  - Check queue saturation (`ZEROGRAVITY_QUEUE_MAX_SIZE`, timeout settings).
  - For repeated 429s, verify multi-account rotation and quota cap config.
  - For 503 capacity errors, retry with backoff and/or switch to a less constrained model.
  - For context/body errors, trim history, tool output, and uploaded content size.

## OpenCode

- **Supported endpoint style:**
  - Preferred: Gemini v1beta-compatible (`/v1beta/models/{model}:{action}`)
  - Alternative: OpenAI-compatible (`/v1/chat/completions` or `/v1/responses`)
- **Proxy-side transformations that affect UX:**
  - Gemini path is pass-through (least translation overhead).
  - OpenAI path translates messages/tools to Gemini and back.
  - Queue controls serialize requests under contention.
  - Missing max-output fields receive proxy defaults.
- **Recommended defaults:**
  - Use Gemini protocol in OpenCode provider config where possible.
  - Keep declared model limits aligned with real context/output ceilings.
  - Use a single shared base URL per workspace to avoid split routing.
- **Anti-patterns:**
  - Mixing multiple incompatible provider plugins for the same ZeroGravity endpoint.
  - Inflating context/output limits above what models support.
  - Running many parallel subagents without queue tuning.
- **Troubleshooting checklist (429/503/capacity/context):**
  - Verify provider points to `http://localhost:8741/v1beta` (preferred) or `/v1` as intended.
  - Inspect proxy logs for queue timeout vs upstream capacity failures.
  - Reduce parallel jobs/subagents if queue depth or 503s spike.
  - Lower context payload and tool transcript size when context errors appear.

## Generic OpenAI-compatible clients

- **Supported endpoint style:** `/v1/chat/completions` and `/v1/responses`.
- **Proxy-side transformations that affect UX:**
  - OpenAI schema is translated into Gemini-compatible upstream requests.
  - Tool/function declarations are normalized to match Gemini constraints.
  - Missing `max_completion_tokens`/`max_output_tokens` defaults to proxy values.
  - Queue/backoff behavior can surface as wait time, 408 timeout, or 503 overloaded responses.
  - API request size is limited by `ZEROGRAVITY_API_BODY_LIMIT_MB` (default 32 MiB, clamped 1..100).
- **Recommended defaults:**
  - Explicitly set max output tokens and stream when client UX expects incremental output.
  - Keep tool JSON schema conservative and standards-compliant.
  - Configure retry with jittered backoff for 429/503.
- **Anti-patterns:**
  - Assuming OpenAI-specific schema extensions always survive translation.
  - Sending oversized one-shot payloads instead of pruning or chunking context.
  - Unbounded client-side concurrency against a single account.
- **Troubleshooting checklist (429/503/capacity/context):**
  - Confirm base URL points at `/v1` and model name is valid.
  - On 429, inspect quota and account rotation health.
  - On 503, differentiate queue overload vs upstream capacity, then tune queue/concurrency.
  - On context/body failures, reduce message/tool size and verify body limit settings.

## Anthropic-compatible clients

- **Supported endpoint style:** `/v1/messages` (+ `/v1/messages/count_tokens` when used).
- **Proxy-side transformations that affect UX:**
  - Anthropic Messages format is translated to Gemini-backed upstream calls.
  - `budget_tokens` maps to Gemini thinking level tiers for Claude aliases.
  - Missing `max_tokens` is defaulted by the proxy.
  - Queue and upstream cooldown behavior can present as delayed starts or transient 429/503.
- **Recommended defaults:**
  - Keep model IDs on supported aliases and pin known-good defaults in client config.
  - Use bounded `max_tokens` and moderate thinking budgets.
  - Keep retry policy enabled with exponential backoff.
- **Anti-patterns:**
  - Over-relying on huge `budget_tokens` values for quality gains.
  - Treating every 503 as proxy failure (capacity exhaustion is often upstream).
  - Sending unnecessary full-session transcripts each turn.
- **Troubleshooting checklist (429/503/capacity/context):**
  - Validate `ANTHROPIC_BASE_URL` and authentication header format.
  - Check `/v1/accounts/status` and `/v1/quota` for exhaustion/cooldown clues.
  - Retry 503 capacity errors with backoff or shift to a lighter model.
  - Trim conversation/tool history when context limits are hit.

