# Model Requirements Guide

## Minimum compatibility requirements

For a model to function in Claude Code at all, four conditions must hold. These are compatibility requirements, not performance concerns. A model missing any one of them will break the agentic loop.

**1. Tool use in Anthropic format**

The model must emit correctly structured `tool_use` content blocks and handle `tool_result` blocks in the message history. This is the hard gate. Every action Claude Code takes -- reading files, running bash, writing code -- is a tool call. A model that cannot produce valid tool call responses cannot take any action.

To verify before assigning a model to a slot, either check the provider's documented supported parameters for their Anthropic endpoint, or send a minimal tool use request and confirm `stop_reason` is `tool_use` in the response.

**2. Streaming**

Responses must stream. Claude Code does not operate in single-turn completion mode.

**3. Large context handling**

The message array passed on each turn includes the system prompt, CLAUDE.md, tool definitions, and the full conversation history. This compounds quickly on real codebases. 32K minimum context window, 128K+ preferred. The model must not degrade or truncate silently under load.

**4. Interleaved tool results in message history**

The messages array is not plain text turns. It contains `tool_use` and `tool_result` blocks interleaved throughout the conversation. The model must handle this structure correctly across the full session, not just on the first turn.

---

## Capability declarations

Capabilities are declared in the provider file via `_SUPPORTED_CAPABILITIES` environment variables. These are Claude Code client-side flags. They control which Anthropic API parameters Claude Code includes in its requests and which UI features it surfaces.

The reference mapping lives in `docs/capabilities-reference.md`. That file defines which Anthropic API parameter each capability string unlocks. When building a provider file, the workflow is:

```
provider's Anthropic endpoint docs
        |
        v
which request parameters does this model support
        |
        v
map to capability strings via capabilities-reference.md
        |
        v
populate _SUPPORTED_CAPABILITIES in the provider file
```

If `_SUPPORTED_CAPABILITIES` is unset, Claude Code falls back to ID-based detection. For non-Anthropic model IDs that do not match Claude's internal patterns, detection returns empty and all advanced capabilities are disabled. The session still runs but as a bare request with no thinking, no effort control, and no related UI features.

If `_SUPPORTED_CAPABILITIES` is set to any value, it becomes a strict allowlist. Capabilities not listed are explicitly disabled even if the model supports them. Do not set it to an empty string -- either populate it correctly or omit it entirely.

---

## Claude Code's three-tier architecture

Claude Code routes tasks across three model slots internally. You do not control which slot a task lands in. You control what model sits in each slot.

```
task complexity -> tier selection (Claude Code decides)
tier selection  -> model string  (you decide via env vars)
model string    -> API request   (LLMswitch routes)
```

### Opus slot

Called for complex planning, hard reasoning gates, and tasks requiring synthesis of large context. Used less frequently than the Sonnet slot -- most coding work does not reach it. Because it is called infrequently and for the hardest tasks, degrading this slot to save cost is a poor trade.

Controlled by: `ANTHROPIC_DEFAULT_OPUS_MODEL`

### Sonnet slot

The workhorse. The majority of token spend lands here. Writing and editing code, reading files, executing multi-step agentic loops, general task execution. Model quality in this slot has the highest impact on both output quality and cost. This is where evaluation effort should be concentrated.

Controlled by: `ANTHROPIC_DEFAULT_SONNET_MODEL`

### Haiku slot

Fast and cheap tier. Quick completions, background classification, spawned subagent work. Strong reasoning is not required here. Optimize for speed, cost, and reliable tool use.

Controlled by: `ANTHROPIC_DEFAULT_HAIKU_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL`

---

## Slot assignment patterns

These are strategy patterns, not fixed configurations. Model names given as current examples -- substitute equivalents from your provider as the landscape evolves.

### Maximum quality

All slots filled with the strongest available models. Cost is secondary. Appropriate when correctness matters more than spend, or when operating on a flat-rate subscription where per-token cost is not a concern.

```bash
# Opus slot: strongest available reasoning model
ANTHROPIC_DEFAULT_OPUS_MODEL="<frontier-reasoning-model>"
# example: qwen/qwen3-235b-a22b, deepseek/deepseek-r1

# Sonnet slot: strongest available coding model
ANTHROPIC_DEFAULT_SONNET_MODEL="<frontier-coding-model>"
# example: google/gemini-2.5-pro, deepseek/deepseek-chat-v3

# Haiku slot: fast model with reliable tool use
ANTHROPIC_DEFAULT_HAIKU_MODEL="<fast-cheap-model>"
CLAUDE_CODE_SUBAGENT_MODEL="<fast-cheap-model>"
# example: google/gemini-flash-2.0, meta-llama/llama-3.3-70b-instruct
```

### Cost optimized, quality maintained

Sonnet slot uses a strong but cheap model. Opus slot kept at a capable reasoning model since it is called infrequently and cost impact is low. Haiku slot optimized purely for speed and cost.

```bash
# Opus slot: capable reasoning model, low frequency so cost impact is small
ANTHROPIC_DEFAULT_OPUS_MODEL="<reasoning-capable-model>"
# example: deepseek/deepseek-r1

# Sonnet slot: strong tool use and code quality at lower cost
ANTHROPIC_DEFAULT_SONNET_MODEL="<cost-efficient-coding-model>"
# example: deepseek/deepseek-chat-v3, mistral/mistral-large

# Haiku slot: fastest and cheapest available
ANTHROPIC_DEFAULT_HAIKU_MODEL="<fast-cheap-model>"
CLAUDE_CODE_SUBAGENT_MODEL="<fast-cheap-model>"
# example: google/gemini-flash-2.0
```

### Homogeneous

Same model across all slots. Appropriate when a single model is capable enough for all tiers and you want to simplify the configuration. Reduces the number of models to evaluate and maintain.

```bash
ANTHROPIC_DEFAULT_OPUS_MODEL="<strong-general-model>"
ANTHROPIC_DEFAULT_SONNET_MODEL="<strong-general-model>"
ANTHROPIC_DEFAULT_HAIKU_MODEL="<strong-general-model>"
CLAUDE_CODE_SUBAGENT_MODEL="<strong-general-model>"
# example: google/gemini-2.5-pro across all slots
```

### Experimental

Dedicated provider file for evaluating new models without touching your working configuration. Run in parallel against a real task and compare output quality and cost before promoting to a primary profile.

```bash
# Opus slot: experimental reasoning model under evaluation
ANTHROPIC_DEFAULT_OPUS_MODEL="<model-under-evaluation>"

# Sonnet slot: experimental coding model under evaluation
ANTHROPIC_DEFAULT_SONNET_MODEL="<model-under-evaluation>"

# Haiku slot: keep a known-good model here to isolate variables
ANTHROPIC_DEFAULT_HAIKU_MODEL="<known-good-fast-model>"
CLAUDE_CODE_SUBAGENT_MODEL="<known-good-fast-model>"
```

---

## Slot evaluation criteria

### Opus slot

Priority order:
1. Multi-step reasoning quality on ambiguous tasks
2. Performance on large context synthesis
3. Cost (low weight -- slot is called infrequently)

### Sonnet slot

Priority order:
1. Tool use reliability under multi-step agentic workloads, not just single function calls
2. Instruction following on long precise system prompts
3. Code generation quality in your primary languages
4. Context window size (32K minimum, 128K+ preferred)
5. Cost per token (high weight -- this is where most spend lands)

### Haiku slot

Priority order:
1. Tool use reliability (still required)
2. Latency
3. Cost per token
4. Reasoning quality (low weight -- not the purpose of this slot)

---

## Provider file structure

Each provider file is self-contained. It sets routing config and capability declarations together. Capability declarations must match what the specific model on that provider's Anthropic endpoint actually supports.

```bash
# Provider: <name>
# Sourced by cc-use, never executed directly.

export ANTHROPIC_BASE_URL="<provider-anthropic-endpoint>"
export ANTHROPIC_AUTH_TOKEN="$<PROVIDER_API_KEY_VAR>"
export ANTHROPIC_API_KEY=""

# Opus slot
export ANTHROPIC_DEFAULT_OPUS_MODEL="<model-id>"
export ANTHROPIC_DEFAULT_OPUS_MODEL_NAME="<display-name>"
export ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION="<one-line description>"
export ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES="<capability-strings>"

# Sonnet slot
export ANTHROPIC_DEFAULT_SONNET_MODEL="<model-id>"
export ANTHROPIC_DEFAULT_SONNET_MODEL_NAME="<display-name>"
export ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION="<one-line description>"
export ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES="<capability-strings>"

# Haiku slot
export ANTHROPIC_DEFAULT_HAIKU_MODEL="<model-id>"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME="<display-name>"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION="<one-line description>"
export ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES="<capability-strings>"

export CLAUDE_CODE_SUBAGENT_MODEL="<model-id>"
```

For capability string values, see `docs/capabilities-reference.md`.

---

## Using multiple provider files

Create a dedicated file per strategy rather than editing a single file when switching configurations. Each file is independently tracked in version control and can be iterated on without affecting others.

```
providers/
├── <provider>-quality.sh       # Maximum quality configuration
├── <provider>-budget.sh        # Cost optimized configuration
├── <provider>-experimental.sh  # Models under evaluation
└── <provider>-homogeneous.sh   # Single model across all slots
```

Switch between configurations:

```sh
cc-use <provider>-budget
cc-use <provider>-experimental
cc-use <provider>-quality
```
