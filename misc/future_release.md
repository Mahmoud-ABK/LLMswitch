# Planned: normalization proxy

The current implementation handles provider switching at the env var level. The next layer is a local HTTP proxy that sits between Claude Code and the upstream provider, normalizing the request and response payloads so non-Anthropic models behave as close to the Anthropic API contract as possible.

```
Claude Code
    -> localhost:PORT (normalization proxy)
        -> request normalization
        -> upstream provider (OpenRouter / DeepSeek / etc.)
        -> response normalization
    -> Claude Code
```

`ANTHROPIC_BASE_URL` in the provider file would point to localhost instead of the upstream directly.

## Planned normalization cases

`thinking` block conversion: strips `thinking` blocks from outgoing history and converts them to text blocks wrapped in `<thinking>` tags before forwarding. Preserves the semantic signal for the receiving model without triggering unknown block type errors.

```json
{"type": "thinking", "thinking": "..."}
->
{"type": "text", "text": "<thinking>\n...\n</thinking>"}
```

`tool_use` / `tool_result` format translation: Anthropic uses `input` (object) for tool arguments. OpenAI-compatible endpoints use `arguments` (JSON string). Needed if routing to raw OpenAI-compatible endpoints directly without going through OpenRouter's Anthropic skin.

Usage field normalization: Anthropic returns `cache_read_input_tokens` and `cache_creation_input_tokens` in the usage object. Non-Anthropic providers omit these. The proxy would inject zero values so Claude Code's cost tracking and budget management do not break on missing fields.

Streaming event translation: Anthropic's SSE stream uses specific event names (`content_block_start`, `content_block_delta`, `content_block_stop`). Raw OpenAI-compatible streams use a different schema. Needed for direct endpoint access outside OpenRouter.

The proxy would live at `~/.claude/LLMswitch/proxy/` and provider files that use it would be responsible for starting it if not already running before setting `ANTHROPIC_BASE_URL`.
