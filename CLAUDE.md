# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

LLMswitch (also called `apiswitcher`) is a shell-native provider switcher for Claude Code. It manages `ANTHROPIC_*` env vars by sourcing provider files into the current shell session, allowing instant switching between Anthropic Pro (OAuth), Anthropic API (billed), and OpenRouter without restarting anything.

The repo lives at `~/.claude/LLMswitch/` and is referenced in some older docs as `~/.claude/apiswitcher/`.

## Setup

```zsh
# 1. Fill in API keys
cp .env.example .env && nano .env

# 2. Source bootstrap from zshrc (one-time)
echo 'source ~/.claude/LLMswitch/bootstrap.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Shell commands (defined in bootstrap.zsh)

```zsh
cc-use <provider>     # switch active provider (sources provider file into current shell)
cc-status             # show active provider and all relevant env vars
cc-providers          # list available providers, marks the active one
```

## Architecture

**Provider switching works via shell sourcing**, not subprocesses. `cc-use` runs `. providers/<name>.sh` inside the current shell so exports take effect immediately without a new terminal.

**State persistence**: the active provider name is written to `${TMPDIR:-/tmp}/.cc_provider`. On shell startup, `bootstrap.zsh` re-sources the last-used provider file from that state.

**Env vars Claude Code reads** (in priority order: `settings.json` > env vars > defaults):
- `ANTHROPIC_BASE_URL` — endpoint (unset = direct Anthropic)
- `ANTHROPIC_API_KEY` — API key (empty string disables OAuth fallback)
- `ANTHROPIC_AUTH_TOKEN` — bearer token for non-Anthropic endpoints
- `ANTHROPIC_DEFAULT_OPUS_MODEL` — model for heavy reasoning tasks
- `ANTHROPIC_DEFAULT_SONNET_MODEL` — model for most coding work (highest token spend)
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` — model for fast/cheap background tasks
- `CLAUDE_CODE_SUBAGENT_MODEL` — model for spawned subagents

## Adding a provider

Create `providers/<name>.sh` — it will be picked up by `cc-use` and `cc-providers` automatically. The file must set/unset the env vars above as appropriate. See `providers/openrouter.sh` for a full example.

Add any new API key to `.env` (untracked) and `.env.example` (tracked, with a placeholder value).

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

When resuming a session across providers, history containing `thinking` content blocks will fail or behave unexpectedly on endpoints that do not implement extended thinking. A normalization proxy (planned, not yet implemented) would handle this by converting `thinking` blocks to text before forwarding.
