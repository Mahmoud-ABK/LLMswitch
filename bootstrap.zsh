# Claude Code API Switcher
# Source this from ~/.zshrc:
#   source ~/.claude/apiswitcher/bootstrap.zsh

_APISWITCHER_DIR="${0:A:h}"
_APISWITCHER_ENV="$_APISWITCHER_DIR/.env"
_APISWITCHER_PROVIDERS="$_APISWITCHER_DIR/providers"
_APISWITCHER_STATE="${TMPDIR:-/tmp}/.cc_provider"

# Load keys from .env on shell startup
if [[ -f "$_APISWITCHER_ENV" ]]; then
  source "$_APISWITCHER_ENV"
else
  echo "[apiswitcher] warning: $_APISWITCHER_ENV not found, run: cp $_APISWITCHER_DIR/.env.example $_APISWITCHER_ENV"
fi

# Restore last used provider across shell sessions
if [[ -f "$_APISWITCHER_STATE" ]]; then
  _last_provider=$(cat "$_APISWITCHER_STATE")
  if [[ -f "$_APISWITCHER_PROVIDERS/$_last_provider.sh" ]]; then
    source "$_APISWITCHER_PROVIDERS/$_last_provider.sh"
  fi
fi

# Switch provider
cc-use() {
  local provider="$1"

  if [[ -z "$provider" ]]; then
    echo "usage: cc-use <provider>"
    echo "available: $(ls $_APISWITCHER_PROVIDERS/*.sh 2>/dev/null | xargs -I{} basename {} .sh | tr '\n' ' ')"
    return 1
  fi

  local provider_file="$_APISWITCHER_PROVIDERS/$provider.sh"

  if [[ ! -f "$provider_file" ]]; then
    echo "[apiswitcher] unknown provider: $provider"
    echo "available: $(ls $_APISWITCHER_PROVIDERS/*.sh 2>/dev/null | xargs -I{} basename {} .sh | tr '\n' ' ')"
    return 1
  fi

  source "$provider_file"
  echo "$provider" >"$_APISWITCHER_STATE"
  echo "[apiswitcher] switched to: $provider"
}

# Show current state of all relevant env vars
cc-status() {
  local current=""
  [[ -f "$_APISWITCHER_STATE" ]] && current=$(cat "$_APISWITCHER_STATE")

  echo "provider  : ${current:-unknown}"
  echo "base_url  : ${ANTHROPIC_BASE_URL:-"(not set, using Anthropic default)"}"
  echo "api_key   : ${ANTHROPIC_API_KEY:+"set"}${ANTHROPIC_API_KEY:-"(empty)"}"
  echo "auth_token: ${ANTHROPIC_AUTH_TOKEN:+"set"}${ANTHROPIC_AUTH_TOKEN:-"(not set)"}"
  echo "opus      : ${ANTHROPIC_DEFAULT_OPUS_MODEL:-"(not set, using Claude Code default)"}"
  echo "sonnet    : ${ANTHROPIC_DEFAULT_SONNET_MODEL:-"(not set, using Claude Code default)"}"
  echo "haiku     : ${ANTHROPIC_DEFAULT_HAIKU_MODEL:-"(not set, using Claude Code default)"}"
  echo "subagent  : ${CLAUDE_CODE_SUBAGENT_MODEL:-"(not set, using Claude Code default)"}"
}

# List available providers
cc-providers() {
  echo "available providers:"
  for f in "$_APISWITCHER_PROVIDERS"/*.sh; do
    local name=$(basename "$f" .sh)
    local current=""
    [[ -f "$_APISWITCHER_STATE" ]] && [[ "$(cat $_APISWITCHER_STATE)" == "$name" ]] && current=" (active)"
    echo "  $name$current"
  done
}
