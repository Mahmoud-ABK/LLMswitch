# Provider: OpenRouter (set2)
# Sourced by cc-use, never executed directly

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""

# Heavy reasoning, complex planning.
export ANTHROPIC_DEFAULT_OPUS_MODEL="openai/gpt-oss-120b:free"
export ANTHROPIC_DEFAULT_OPUS_MODEL_NAME="GPT OSS 120B Free (Opus)"
export ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION="Heavy reasoning and complex planning tasks."
export ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES=""

# Most code work — highest token spend.
export ANTHROPIC_DEFAULT_SONNET_MODEL="nvidia/nemotron-3-super-120b-a12b"
export ANTHROPIC_DEFAULT_SONNET_MODEL_NAME="Nemotron Super 120B (Sonnet)"
export ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION="General coding and agentic workflows."
export ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES=""

# Fast completions and subagents.
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek/deepseek-v4-flash"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME="DeepSeek V4 Flash (Haiku)"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION="Fast completions, background tasks, and subagents."
export ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES=""

export CLAUDE_CODE_SUBAGENT_MODEL="deepseek/deepseek-v4-flash"
