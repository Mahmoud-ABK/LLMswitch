# Provider: OpenRouter (example)
# Sourced by cc-use, never executed directly.
# Copy to providers/<name>.sh, fill in models, and add key to .env.

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""

# Heavy reasoning, complex planning.
export ANTHROPIC_DEFAULT_OPUS_MODEL="provider/model-strong"
export ANTHROPIC_DEFAULT_OPUS_MODEL_NAME="Model Strong (Opus)"
export ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION="Heavy reasoning and complex planning tasks."
export ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES=""

# Most code work — highest token spend.
export ANTHROPIC_DEFAULT_SONNET_MODEL="provider/model-balanced"
export ANTHROPIC_DEFAULT_SONNET_MODEL_NAME="Model Balanced (Sonnet)"
export ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION="General coding and agentic workflows."
export ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES=""

# Fast completions and subagents.
export ANTHROPIC_DEFAULT_HAIKU_MODEL="provider/model-fast"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME="Model Fast (Haiku)"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION="Fast completions, background tasks, and subagents."
export ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES=""

export CLAUDE_CODE_SUBAGENT_MODEL="provider/model-fast"
