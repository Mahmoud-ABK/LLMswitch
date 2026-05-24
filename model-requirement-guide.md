# How to Choose Models in LLMswitch

## Claude Code's three-tier architecture

Claude Code does not work with a single model. Internally it operates across three task tiers, each mapped to a different model slot. Understanding this is the foundation of any cost/quality optimization strategy.

### Tier 1: Opus slot

The heavyweight tier. Claude Code reaches for this slot when it needs to:

- Plan a complex multi-step task before execution
- Reason through an ambiguous problem with no clear path
- Handle tasks that require synthesizing large amounts of context

In practice Claude Code does not use this slot as often as you might expect. Most coding work lands in the Sonnet slot. Opus gets called for the hard reasoning gates.

Controlled by: `ANTHROPIC_DEFAULT_OPUS_MODEL`

### Tier 2: Sonnet slot

The workhorse tier. This is where the majority of your token spend goes. Claude Code uses this slot for:

- Writing and editing code
- Reading and understanding files
- Executing multi-step agentic loops
- Most general task execution

This slot has the highest impact on both quality and cost. Choosing the right model here is the most important decision.

Controlled by: `ANTHROPIC_DEFAULT_SONNET_MODEL`

### Tier 3: Haiku slot

The fast and cheap tier. Claude Code uses this for:

- Quick completions
- Background classification tasks
- Spawned subagent work
- Anything that does not need full reasoning capability

Controlled by: `ANTHROPIC_DEFAULT_HAIKU_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL`

---

## How Claude Code picks a tier

Claude Code decides which tier to use based on the task internally. You do not control this directly. What you control is what model sits in each slot. The mapping is fixed:

```
task complexity -> tier selection (Claude Code decides)
tier selection  -> model string (you decide via env vars)
model string    -> API request (LLMswitch routes)
```

This means model selection is a slot-filling exercise. You are not telling Claude Code which model to use for a specific task. You are telling it what to use when it decides to reach for a given tier.

---

## The only hard requirement for any model

The model must support tool use (function calling) in Anthropic format. Claude Code's entire agentic loop is tool calls: reading files, running bash, writing code. A model that cannot emit a valid tool use block cannot take any action in Claude Code.

Everything else, context length, instruction following quality, code generation quality, is a performance concern not a compatibility concern.

To verify a model supports tool use before assigning it to a slot:

- Check `https://openrouter.ai/models?supported_parameters=tools` for OpenRouter models
- Or send a minimal tool use request and check that `stop_reason` is `tool_use` in the response

---

## Decision framework per slot

### Opus slot

You have two options:

Keep a strong Anthropic model here even when using non-Anthropic models for Sonnet. The Opus slot is called infrequently so the cost impact is low, and the tasks it handles are precisely the ones where model quality matters most. Degrading this slot to save money is a bad trade.

Or assign the same model as Sonnet if the model you chose is already strong enough for reasoning tasks. Many modern frontier models (DeepSeek R1, Gemini 2.5 Pro) are capable enough that a separate Opus-class model is not necessary.

### Sonnet slot

This is where you should spend the most time evaluating. Criteria in order of importance:

1. Tool use reliability under multi-step agentic workloads, not just single function calls
2. Instruction following on long, precise system prompts
3. Code generation quality in your primary languages
4. Context window size (32K minimum, 128K+ preferred for large codebases)
5. Cost per token

### Haiku slot

Optimize purely for speed and cost here. The tasks routed to this slot do not need strong reasoning. A fast, cheap model with reliable tool use is the right choice. Gemini Flash and Claude Haiku are the current reference points for this tier.

---

## Practical model assignments by strategy

### Maximum quality (cost secondary)

```bash
ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic/claude-opus-4-5"
ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic/claude-sonnet-4-5"
ANTHROPIC_DEFAULT_HAIKU_MODEL="anthropic/claude-haiku-4-5"
CLAUDE_CODE_SUBAGENT_MODEL="anthropic/claude-haiku-4-5"
```

Use `claudepro` provider for this. Flat rate, no per-token cost.

### Cost optimized, quality maintained

```bash
ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic/claude-sonnet-4-5"
ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek/deepseek-chat"
ANTHROPIC_DEFAULT_HAIKU_MODEL="google/gemini-flash-1.5"
CLAUDE_CODE_SUBAGENT_MODEL="google/gemini-flash-1.5"
```

DeepSeek Chat has strong tool use and good code quality at a fraction of Sonnet's price. Gemini Flash is fast and cheap for background tasks.

### Experimental / evaluation

```bash
ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek/deepseek-r1"
ANTHROPIC_DEFAULT_SONNET_MODEL="google/gemini-2.5-pro"
ANTHROPIC_DEFAULT_HAIKU_MODEL="google/gemini-flash-1.5"
CLAUDE_CODE_SUBAGENT_MODEL="google/gemini-flash-1.5"
```

Use this configuration via a dedicated provider file (e.g. `openrouter-experimental.sh`) so it does not interfere with your default setup.

---

## Using separate provider files per strategy

Rather than editing `openrouter.sh` when you want to try a different model mix, create a dedicated provider file per strategy:

```
providers/
├── claudepro.sh              # Anthropic Pro subscription, all Claude models
├── anthropic.sh              # Anthropic API billed, all Claude models
├── openrouter.sh             # OpenRouter, Claude models (overflow / rate limit)
├── openrouter-budget.sh      # OpenRouter, mixed cheap models
└── openrouter-experimental.sh # OpenRouter, non-Anthropic frontier models
```

Switch between strategies cleanly:

```zsh
cc-use openrouter-budget
cc-use openrouter-experimental
cc-use claudepro
```

Each file is self-contained and independently tracked in git. You can iterate on one strategy without affecting others.

---

## Model compatibility reference

| Model | Tool use | Thinking blocks | Recommended slot |
|---|---|---|---|
| `anthropic/claude-opus-4-5` | yes | yes | Opus |
| `anthropic/claude-sonnet-4-5` | yes | yes | Sonnet |
| `anthropic/claude-haiku-4-5` | yes | no | Haiku |
| `deepseek/deepseek-chat` | yes | no | Sonnet |
| `deepseek/deepseek-r1` | yes | no (converted) | Opus / Sonnet |
| `google/gemini-2.5-pro` | yes | no | Sonnet |
| `google/gemini-flash-1.5` | yes | no | Haiku |
| `openai/gpt-4o` | yes | no | Sonnet |
| `meta-llama/llama-3.1-405b` | partial | no | Sonnet (degraded) |

Thinking block support means the model returns structured `thinking` content blocks via the API endpoint, not that the model is incapable of reasoning internally. See the normalization proxy section in README.md for how LLMswitch handles thinking block conversion for non-Anthropic models.
