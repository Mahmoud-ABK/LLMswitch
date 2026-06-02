# Capabilities Reference

Capability strings for `_SUPPORTED_CAPABILITIES` and their exact Anthropic API translations.

Source: [Claude Code model configuration](https://code.claude.com/docs/en/model-config), [Extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking), [Adaptive thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking), [Effort](https://platform.claude.com/docs/en/build-with-claude/effort)

---

## How capability strings work

`_SUPPORTED_CAPABILITIES` is a Claude Code client-side mechanism. When Claude Code builds an Anthropic API request, it checks this variable to decide which parameters to include. The variable has no meaning at the API level -- it is never sent to the provider.

When the variable is **unset**, Claude Code falls back to ID-based detection against its internal model table. Non-Anthropic model IDs produce no matches, so all advanced capabilities are disabled.

When the variable is **set**, it becomes a strict allowlist. Capabilities not listed are disabled even if the model supports them. An empty string is a valid set value and disables everything. Either populate it correctly or omit the variable entirely.

---

## Capability strings

### `thinking`

**What Claude Code does:** Sends `thinking: {type: "enabled", budget_tokens: N}` in the request body.

**Anthropic API parameter:**
```json
{
  "thinking": {
    "type": "enabled",
    "budget_tokens": 10000
  }
}
```

**What the model must do:** Produce `thinking` content blocks in the response before the final `text` block. The model must have been trained to output structured reasoning traces in Anthropic's thinking block format.

**Important constraint:** On Claude Opus 4.8 and Opus 4.7, manual extended thinking (`type: "enabled"`) is not supported and returns a 400 error. Those models use `adaptive_thinking` only. For third-party models, use this capability string only if the model's provider explicitly documents support for the `thinking: {type: "enabled", budget_tokens: N}` parameter on their Anthropic endpoint.

---

### `adaptive_thinking`

**What Claude Code does:** Sends `thinking: {type: "adaptive"}` in the request body.

**Anthropic API parameter:**
```json
{
  "thinking": {
    "type": "adaptive"
  }
}
```

**What the model must do:** Dynamically decide whether and how much to think on each step based on task complexity. The model allocates thinking based on the effort level rather than a fixed token budget. Produces thinking blocks only when the model judges them necessary for the request.

**Relationship to effort:** Adaptive thinking and effort work together. Effort controls the depth of thinking; adaptive thinking decides when to think at all. At `high`, `xhigh`, and `max` effort, the model almost always thinks. At `low` and `medium`, it may skip thinking for simpler steps.

---

### `interleaved_thinking`

**What Claude Code does:** Enables thinking blocks between tool calls, not only at the start of a response.

**Anthropic API behavior:** Claude produces thinking blocks between consecutive tool calls within a single assistant turn, allowing it to reason about tool results before deciding the next action.

**What the model must do:** Support reasoning between tool calls, not just at the start of a turn. This is a distinct training requirement from general thinking support. A model with `thinking` or `adaptive_thinking` may not have `interleaved_thinking` if it was not trained for mid-turn reasoning.

**Note on beta header:** The `interleaved-thinking-2025-05-14` beta header is deprecated on Opus 4.6 and later and is safely ignored. On Opus 4.8, Opus 4.7, and Opus 4.6, interleaved thinking is automatically enabled when using adaptive thinking -- no beta header or separate declaration is needed. Declare this capability for third-party models only if their provider documents support for thinking blocks between tool calls.

---

### `effort`

**What Claude Code does:** Enables the `/effort` command and effort slider in the `/model` picker. Sends `output_config: {effort: "low" | "medium" | "high"}` in the request body.

**Anthropic API parameter:**
```json
{
  "output_config": {
    "effort": "high"
  }
}
```

**Effort levels covered by this string:** `low`, `medium`, `high`. These are the baseline levels. `xhigh` and `max` require additional capability strings.

**What the model must do:** Modulate token spend based on the effort signal. At lower effort, the model should make fewer tool calls, produce terser output, and skip reasoning for simpler problems. At higher effort, it should reason more thoroughly and use more tool calls. This requires training, not just parameter acceptance.

**Default behavior:** If `effort` is declared but no level is set, Claude Code defaults to `high` for most models.

---

### `xhigh_effort`

**What Claude Code does:** Adds the `xhigh` level to the effort slider. Sends `output_config: {effort: "xhigh"}`.

**Anthropic API parameter:**
```json
{
  "output_config": {
    "effort": "xhigh"
  }
}
```

**Requires:** `effort` must also be declared. `xhigh_effort` is additive on top of the baseline effort capability.

**Native model support:** Opus 4.8 and Opus 4.7 only. Opus 4.6 and Sonnet 4.6 do not support `xhigh`; Claude Code falls back to `high` if `xhigh` is requested on those models.

**Use case:** Long-horizon agentic and coding tasks, over 30 minutes, with token budgets in the millions.

---

### `max_effort`

**What Claude Code does:** Adds the `max` level to the effort slider. Sends `output_config: {effort: "max"}`.

**Anthropic API parameter:**
```json
{
  "output_config": {
    "effort": "max"
  }
}
```

**Requires:** `effort` must also be declared. `max_effort` is additive on top of the baseline effort capability.

**Session behavior:** `max` applies to the current session only and is not persisted across sessions, unlike `low`, `medium`, `high`, and `xhigh`.

**Native model support:** Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6, Opus 4.5. Not supported on Haiku 4.5.

---

## Full capability string reference

| Capability string | Anthropic API parameter | Enables in Claude Code UI |
|---|---|---|
| `thinking` | `thinking: {type: "enabled", budget_tokens: N}` | Thinking toggle (`Option+T` / `Alt+T`) |
| `adaptive_thinking` | `thinking: {type: "adaptive"}` | Thinking toggle, adaptive mode |
| `interleaved_thinking` | Thinking blocks between tool calls | No separate UI element; extends thinking behavior |
| `effort` | `output_config: {effort: "low\|medium\|high"}` | `/effort` command, effort slider in `/model` |
| `xhigh_effort` | `output_config: {effort: "xhigh"}` | `xhigh` level in effort slider |
| `max_effort` | `output_config: {effort: "max"}` | `max` level in effort slider |

---

## Native Anthropic model capability strings

For reference when building profiles that mix Anthropic and non-Anthropic models.

| Model | Capability string |
|---|---|
| Opus 4.8 | `adaptive_thinking,interleaved_thinking,effort,xhigh_effort,max_effort` |
| Opus 4.7 | `adaptive_thinking,interleaved_thinking,effort,xhigh_effort,max_effort` |
| Opus 4.6 | `thinking,adaptive_thinking,interleaved_thinking,effort,max_effort` |
| Sonnet 4.6 | `thinking,adaptive_thinking,interleaved_thinking,effort,max_effort` |
| Haiku 4.5 | `thinking` |

Note: Opus 4.8 and Opus 4.7 do not get the `thinking` string because manual extended thinking returns a 400 error on those models. Haiku 4.5 has no effort support.

---

## Decision rules for third-party models

When populating `_SUPPORTED_CAPABILITIES` for a non-Anthropic model:

1. Check the provider's Anthropic endpoint documentation for which request parameters they accept and forward.
2. Verify the model was trained to respond meaningfully to each parameter -- parameter acceptance by the provider does not guarantee meaningful model behavior.
3. Apply the mapping table above to translate supported parameters to capability strings.
4. When in doubt, omit a capability string rather than declare it. Silent degradation from an undeclared capability is preferable to corrupt behavior from a declared capability the model cannot honor.
5. If `_SUPPORTED_CAPABILITIES` is set at all, it must be complete. Partial declarations silently disable unlisted capabilities.
