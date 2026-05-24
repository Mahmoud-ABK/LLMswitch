# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

LLMswitch is a shell-native provider switcher for Claude Code. It manages `ANTHROPIC_*` env vars by sourcing provider files into the current shell session, allowing instant switching between Anthropic Pro (OAuth), Anthropic API (billed), and OpenRouter without restarting anything.

## Setup

```sh
# 1. Fill in API keys
cp .env.example .env && nano .env

# 2. Source bootstrap from shell profile (one-time)
echo 'source ~/.claude/LLMswitch/bootstrap.sh' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

## Shell commands (defined in bootstrap.sh)

```sh
cc-use <provider>     # switch active provider (sources provider file into current shell)
cc-status             # show active provider and all relevant env vars
cc-providers          # list available providers with model assignments, marks the active one
```

## Architecture

**Provider switching works via shell sourcing**, not subprocesses. `cc-use` runs `. providers/<name>.sh` inside the current shell so exports take effect immediately without a new terminal.

**State persistence**: the active provider name is written to `${TMPDIR:-/tmp}/.cc_provider`. On shell startup, `bootstrap.sh` re-sources the last-used provider file from that state.

**Env vars Claude Code reads** (in priority order: `settings.json` > env vars > defaults):
- `ANTHROPIC_BASE_URL` — endpoint (unset = direct Anthropic)
- `ANTHROPIC_API_KEY` — API key (empty string disables OAuth fallback)
- `ANTHROPIC_AUTH_TOKEN` — bearer token for non-Anthropic endpoints
- `ANTHROPIC_DEFAULT_OPUS_MODEL` — model for heavy reasoning tasks
- `ANTHROPIC_DEFAULT_SONNET_MODEL` — model for most coding work (highest token spend)
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` — model for fast/cheap background tasks
- `CLAUDE_CODE_SUBAGENT_MODEL` — model for spawned subagents

## Adding a provider

Copy `provider.example.sh` to `providers/<name>.sh` and fill in values — the file documents every env var with inline guidance. Add any new API key to `.env` (untracked) and `.env.example` (tracked).

## Tab completion

- **zsh / bash**: registered automatically when `bootstrap.sh` is sourced.
- **fish**: symlink `completions/cc-use.fish` into `~/.config/fish/completions/`.

## Critical: settings.json conflicts

If `~/.claude/settings.json` contains `"model"`, `"defaultModel"`, `"smallFastModel"`, or `"largeContextModel"`, those silently override the env vars set by provider files with no warning. Remove those keys if LLMswitch model assignments are not taking effect.

## Model slots

Claude Code routes tasks to three tiers internally; you control what model fills each slot:

| Slot | Env var | Used for |
|---|---|---|
| Opus | `ANTHROPIC_DEFAULT_OPUS_MODEL` | Complex planning, hard reasoning (called infrequently) |
| Sonnet | `ANTHROPIC_DEFAULT_SONNET_MODEL` | Most code work — highest impact and cost |
| Haiku | `ANTHROPIC_DEFAULT_HAIKU_MODEL` + `CLAUDE_CODE_SUBAGENT_MODEL` | Fast completions, subagents |

**Hard requirement**: any model assigned to a slot must support tool use (function calling) in Anthropic format. See `model-requirement-guide.md` for the full decision framework and a model compatibility table.

## Session continuity caveat

When resuming a session across providers, history containing `thinking` content blocks will fail or behave unexpectedly on endpoints that do not implement extended thinking. A normalization proxy (planned) would handle this — see `misc/future_release.md`.
