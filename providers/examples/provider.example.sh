# Provider: <name>
# Sourced by cc-use, never executed directly.
# Copy to providers/<name>.sh and fill in values.
# Add any new API key to .env (untracked) and .env.example (tracked).

# --- Routing ---

# Your provider's Anthropic-compatible base URL.
# Unset to route directly to Anthropic.
export ANTHROPIC_BASE_URL="https://your-provider.example/api"

# Bearer token for non-Anthropic endpoints (OpenRouter, DeepSeek, etc.)
# Unset if authenticating via ANTHROPIC_API_KEY instead.
export ANTHROPIC_AUTH_TOKEN="$YOUR_PROVIDER_API_KEY"

# Set to "" (empty string, not unset) to disable Claude Code's OAuth fallback
# when the endpoint is not Anthropic. Unset to pass the real Anthropic key.
export ANTHROPIC_API_KEY=""

# --- Model slots ---
# Every model assigned here must support tool use (function calling)
# in Anthropic format — Claude Code's entire agentic loop depends on it.
# Unset any slot to fall back to Claude Code's built-in default.

# Heavy reasoning, complex planning. Called infrequently — prioritize quality.
export ANTHROPIC_DEFAULT_OPUS_MODEL="provider/model-strong"

# Most code work. Highest token spend — most important slot to tune.
export ANTHROPIC_DEFAULT_SONNET_MODEL="provider/model-balanced"

# Fast completions, background tasks. Optimize for speed and cost.
export ANTHROPIC_DEFAULT_HAIKU_MODEL="provider/model-fast"
export CLAUDE_CODE_SUBAGENT_MODEL="provider/model-fast"
