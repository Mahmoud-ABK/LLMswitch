# LLMswitch

A shell-native provider switcher for Claude Code. Lets you switch between Anthropic (Pro subscription), Anthropic (API billing), and OpenRouter without touching your shell profile or restarting anything.

Built as a designated tool rather than a one-off shell alias, so the configuration is version-controlled, portable across machines, and extensible to new providers by dropping a single file.

---

## How it works

Claude Code determines which API to talk to by reading environment variables at startup:

- `ANTHROPIC_BASE_URL`: the endpoint (defaults to Anthropic if unset)
- `ANTHROPIC_AUTH_TOKEN`: bearer token for non-Anthropic endpoints
- `ANTHROPIC_API_KEY`: Anthropic API key (empty string disables OAuth fallback)
- `ANTHROPIC_DEFAULT_*_MODEL`: model overrides per task class

LLMswitch manages these variables by sourcing provider files directly into your current shell session. Sourcing (`. file` or `source file`) runs the file inside the current process rather than a child, so exports land in your live session and Claude Code picks them up immediately on next launch.

Provider state is persisted across shell sessions in a local `.state/` directory so your last used provider is automatically restored when you open a new terminal, including after a reboot.

---

## Structure

```
~/.claude/LLMswitch/
├── .env                        # your API keys, untracked
├── .env.example                # key template, tracked
├── .state/                     # active provider state, untracked
├── bootstrap.sh                # sourced by ~/.zshrc or ~/.bashrc
├── providers/
│   ├── claudepro.sh            # Anthropic Pro/Max (OAuth, subscription)
│   ├── openrouter.sh           # OpenRouter (billed per token via credits)
│   └── examples/               # copy-ready templates, not loaded by cc-use
│       ├── anthropic.sh        # Anthropic API (billed per token)
│       ├── openrouter.sh       # generic OpenRouter template
│       └── provider.example.sh # blank provider template
└── README.md
```

---

## Setup

**0. Remove conflicting `settings.json` keys**

Claude Code reads model configuration in this priority order:

```
settings.json  >  env vars  >  Claude Code defaults
```

If `~/.claude/settings.json` contains any of these keys, they silently override whatever your provider file exports with no warning:

```json
"model"
"defaultModel"
"smallFastModel"
"largeContextModel"
```

Remove them before continuing. The env vars set by provider files should be the single source of truth.

**1. Fill in your keys**

```zsh
cp ~/.claude/LLMswitch/.env.example ~/.claude/LLMswitch/.env
nano ~/.claude/LLMswitch/.env
```

```bash
ANTHROPIC_API_KEY_REAL="sk-ant-xxxxxxxxxxxx"
OPENROUTER_API_KEY="sk-or-xxxxxxxxxxxx"
```

**2. Source the bootstrap from your shell profile**

```zsh
echo 'source ~/.claude/LLMswitch/bootstrap.sh' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

**3. Set up the Pro OAuth session (one time)**

The `claudepro` provider relies on a stored OAuth session in `~/.claude/.credentials.json`. If you have never logged in or logged out previously:

```zsh
cc-use claudepro
claude    # will prompt for login once, stores the session
```

After this initial login the session persists and no further login steps are needed.

---

## Usage

```zsh
cc-use claudepro        # Anthropic Pro/Max subscription
cc-use openrouter       # OpenRouter, billed per token via credits

cc-status               # show current provider and active env vars
cc-providers            # list all available providers with their model assignments
```

Tab completion for `cc-use` is registered automatically in zsh and bash when `bootstrap.sh` is sourced. For fish, symlink the completion file once:

```sh
ln -s ~/.claude/LLMswitch/completions/cc-use.fish ~/.config/fish/completions/cc-use.fish
```

---

## Provider behavior

### `claudepro`

Unsets all API-related env vars and lets Claude Code fall back to the stored OAuth session in `~/.claude/.credentials.json`. Uses your Pro or Max subscription. No per-token billing. Subject to Anthropic's rate limits and fair use policy.

Best for: heavy agentic sessions, large refactors, long multi-file tasks.

### `openrouter`

Sets `ANTHROPIC_BASE_URL` to `https://openrouter.ai/api` and `ANTHROPIC_AUTH_TOKEN` to your OpenRouter key. Sets `ANTHROPIC_API_KEY` to an empty string explicitly (not unset) to prevent Claude Code from falling back to the OAuth session. Also sets model vars to pin specific models per task class.

OpenRouter exposes an Anthropic-compatible API surface ("Anthropic Skin") that handles model mapping and passes through Anthropic-specific features like thinking blocks and native tool use when routing to Anthropic models. Billed per token via OpenRouter credits.

Best for: overflow when hitting Pro rate limits, testing non-Anthropic models, cost control on lighter tasks.

---

## Adding a provider

Copy `providers/examples/provider.example.sh` (or the relevant example in `providers/examples/`) to `providers/<name>.sh` and fill in the values. The file documents every available env var with inline guidance.

Add the corresponding API key to `.env` and `.env.example`.

`cc-use <name>` and `cc-providers` will pick it up automatically with no changes to bootstrap.

---

## State persistence

The active provider name is written to `.state/provider` inside the project directory on every `cc-use` call. On shell startup, `bootstrap.sh` reads this file and re-sources the corresponding provider file so your choice survives closing and reopening the terminal, including across reboots.

The `.state/` directory is created automatically and is gitignored. If the state file is missing or references a provider file that no longer exists, bootstrap silently skips restoration and no provider is active.

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

## Misc

See [misc/future_release.md](misc/future_release.md) for planned features.

