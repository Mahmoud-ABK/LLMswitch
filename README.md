# apiswitcher

A shell-native provider switcher for Claude Code. Lets you switch between Anthropic (Pro subscription), Anthropic (API billing), and OpenRouter without touching your shell profile or restarting anything.

Built as a designated tool rather than a one-off shell alias, so the configuration is version-controlled, portable across machines, and extensible to new providers by dropping a single file.

---

## How it works

Claude Code determines which API to talk to by reading environment variables at startup:

- `ANTHROPIC_BASE_URL`: the endpoint (defaults to Anthropic if unset)
- `ANTHROPIC_AUTH_TOKEN`: bearer token for non-Anthropic endpoints
- `ANTHROPIC_API_KEY`: Anthropic API key (empty string disables OAuth fallback)
- `ANTHROPIC_DEFAULT_*_MODEL`: model overrides per task class

apiswitcher manages these variables by sourcing provider files directly into your current shell session. Sourcing (`. file` or `source file`) runs the file inside the current process rather than a child, so exports land in your live session and Claude Code picks them up immediately on next launch.

Provider state is persisted across shell sessions via a temp file so your last used provider is automatically restored when you open a new terminal.

---

## Structure

```
~/.claude/apiswitcher/
├── .env                    # your API keys, untracked
├── .env.example            # template, tracked
├── bootstrap.zsh           # sourced by ~/.zshrc, registers shell functions
├── providers/
│   ├── anthropic.sh        # Anthropic API (billed per token)
│   ├── anthropicpro.sh     # Anthropic Pro/Max (OAuth, subscription)
│   └── openrouter.sh       # OpenRouter (billed per token via credits)
└── README.md
```

---

## Setup

**1. Fill in your keys**

```zsh
cp ~/.claude/apiswitcher/.env.example ~/.claude/apiswitcher/.env
nano ~/.claude/apiswitcher/.env
```

```bash
ANTHROPIC_API_KEY_REAL="sk-ant-xxxxxxxxxxxx"
OPENROUTER_API_KEY="sk-or-xxxxxxxxxxxx"
```

**2. Source the bootstrap from your shell profile**

```zsh
echo 'source ~/.claude/apiswitcher/bootstrap.zsh' >> ~/.zshrc
source ~/.zshrc
```

**3. Set up the Pro OAuth session (one time)**

The `anthropicpro` provider relies on a stored OAuth session in `~/.claude/.credentials.json`. If you have never logged in or logged out previously:

```zsh
cc-use anthropicpro
claude    # will prompt for login once, stores the session
```

After this initial login the session persists and no further login steps are needed.

---

## Usage

```zsh
cc-use anthropicpro     # Anthropic Pro/Max subscription
cc-use anthropic        # Anthropic API, billed per token
cc-use openrouter       # OpenRouter, billed per token via credits

cc-status               # show current provider and active env vars
cc-providers            # list all available providers
```

---

## Provider behavior

### `anthropicpro`

Unsets all API-related env vars and lets Claude Code fall back to the stored OAuth session in `~/.claude/.credentials.json`. Uses your Pro or Max subscription. No per-token billing. Subject to Anthropic's rate limits and fair use policy.

Best for: heavy agentic sessions, large refactors, long multi-file tasks.

### `anthropic`

Sets `ANTHROPIC_API_KEY` from `.env` and unsets all routing vars so Claude Code talks directly to `api.anthropic.com`. Billed per token at Anthropic's standard API rates.

Best for: programmatic or CI usage where OAuth is not suitable.

### `openrouter`

Sets `ANTHROPIC_BASE_URL` to `https://openrouter.ai/api` and `ANTHROPIC_AUTH_TOKEN` to your OpenRouter key. Sets `ANTHROPIC_API_KEY` to an empty string explicitly (not unset) to prevent Claude Code from falling back to the OAuth session. Also sets model vars to pin specific models per task class.

OpenRouter exposes an Anthropic-compatible API surface ("Anthropic Skin") that handles model mapping and passes through Anthropic-specific features like thinking blocks and native tool use when routing to Anthropic models. Billed per token via OpenRouter credits.

Best for: overflow when hitting Pro rate limits, testing non-Anthropic models, cost control on lighter tasks.

---

## State persistence

The active provider name is written to `${TMPDIR:-/tmp}/.cc_provider` on every `cc-use` call. On shell startup, `bootstrap.zsh` reads this file and re-sources the corresponding provider file so your choice survives closing and reopening the terminal.

If the state file is missing or references a provider file that no longer exists, bootstrap silently skips restoration and no provider is active.

---

## Adding a provider

Create a new file under `providers/`:

```bash
# providers/deepseek.sh

export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
export ANTHROPIC_API_KEY=""

export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
```

Add the corresponding key to `.env`:

```bash
DEEPSEEK_API_KEY="sk-xxxxxxxxxxxx"
```

`cc-use deepseek` and `cc-providers` will pick it up automatically with no changes to bootstrap.

---

## Session continuity across providers

Claude Code stores session history in `~/.claude/projects/<project-hash>/sessions/` as a messages array. When you resume a session, Claude Code replays that history to the currently active endpoint.

For providers that speak the full Anthropic API format (Anthropic directly, or OpenRouter routing to `anthropic/*` models), session resumption works transparently.

For non-Anthropic models, the main compatibility concern is `thinking` content blocks. If a previous session used extended thinking, the history will contain:

```json
{"type": "thinking", "thinking": "...", "signature": "..."}
```

Endpoints that do not implement the thinking feature will either error on this block type or silently drop it. The model loses that reasoning context which can cause behavioral drift in resumed sessions.

---

## Future: normalization proxy

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

**Planned normalization cases:**

`thinking` block conversion: strips `thinking` blocks from outgoing history and converts them to text blocks wrapped in `<thinking>` tags before forwarding. Preserves the semantic signal for the receiving model without triggering unknown block type errors.

```json
{"type": "thinking", "thinking": "..."}
->
{"type": "text", "text": "<thinking>\n...\n</thinking>"}
```

`tool_use` / `tool_result` format translation: Anthropic uses `input` (object) for tool arguments. OpenAI-compatible endpoints use `arguments` (JSON string). Needed if routing to raw OpenAI-compatible endpoints directly without going through OpenRouter's Anthropic skin.

Usage field normalization: Anthropic returns `cache_read_input_tokens` and `cache_creation_input_tokens` in the usage object. Non-Anthropic providers omit these. The proxy would inject zero values so Claude Code's cost tracking and budget management do not break on missing fields.

Streaming event translation: Anthropic's SSE stream uses specific event names (`content_block_start`, `content_block_delta`, `content_block_stop`). Raw OpenAI-compatible streams use a different schema. Needed for direct endpoint access outside OpenRouter.

The proxy would live at `~/.claude/apiswitcher/proxy/` and provider files that use it would be responsible for starting it if not already running before setting `ANTHROPIC_BASE_URL`.

---

## `settings.json` conflicts

Claude Code reads model configuration in this priority order:

```
settings.json  >  env vars  >  Claude Code defaults
```

If `~/.claude/settings.json` contains model-related keys, they will silently override whatever your provider file exports. The env vars are set correctly but have no effect. There is no warning.

Keys to check for and remove:

```json
"model"
"defaultModel"
"smallFastModel"
"largeContextModel"
```

If any of these are present while using LLMswitch, remove them and let the env vars be the single source of truth for model configuration.

---

## .gitignore

`~/.claude/.gitignore` should contain:

```
apiswitcher/.env
```

Everything else in this directory is safe to track.
