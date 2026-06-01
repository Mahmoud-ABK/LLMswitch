# Provider: OpenRouter (example)
# Sourced by cc-use, never executed directly.
# Copy to providers/<name>.sh, fill in models, and add key to .env.

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""

# Heavy reasoning, complex planning.
export ANTHROPIC_DEFAULT_OPUS_MODEL="provider/model-strong"

# Most code work — highest token spend.
export ANTHROPIC_DEFAULT_SONNET_MODEL="provider/model-balanced"

# Fast completions and subagents.
export ANTHROPIC_DEFAULT_HAIKU_MODEL="provider/model-fast"
export CLAUDE_CODE_SUBAGENT_MODEL="provider/model-fast"
