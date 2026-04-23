---
name: diagnose
description: Root-cause investigation, test-driven bug proving, and architecture-first debugging. Invoke whenever you're about to write a try/except/fallback, conclude "flaky" or "can't reproduce", your fix for bug N created bug N+1, a bug you fixed has recurred, a tool/integration fails locally, or you need to trace any symptom back to cause. Also covers races, state machines, and async ordering. Does NOT fix — investigates, proves, documents.
---

# Diagnose

Investigate a reported or suspected bug, trace the root cause, prove it with tests, and document findings. No fixes.

## Core philosophy

**Every bug is evidence of a design that permitted it.** Fix the symptom, then zoom out to the architecture that made it possible and ask whether the design can be reworked to eliminate the entire class of problems. Compatibility shims, parallel paths, and conditional dispatch between old and new systems are design debt that generates bugs — prefer clean replacement over graceful coexistence. Don't add abstractions that "unify" things that shouldn't be separate; fix the separation.

**Never work around issues without explicit permission.** Don't skip failures, find alternatives, or add silent fallbacks that mask them. Only suggest a different approach after asking explicitly ("keep debugging or pivot?"). If the user says "try again" repeatedly, they want the issue fixed, not worked around. Prefer a single explicit path with loud errors and good observability; if a fallback is genuinely needed, make its activation visible and get user approval before adding it.

## When to invoke this skill

Invoke as a mandatory gate — not a soft suggestion — before any of the following:

- Writing a `try/except`, fallback, default value, or conditional that suppresses an error you don't understand
- Concluding *"flaky"*, *"can't reproduce"*, or *"works locally"* on a failing test
- Your fix for bug N has created bug N+1 → stop and zoom out
- A bug you fixed before has recurred (the mental model used for the first fix is wrong or incomplete)
- A tool or integration fails locally → check env / token scopes / network / K8s-only services before assuming code bug
- MCP calls fail or sessions hang → check MCP server health (process count, config versions, startup behavior) before reading app code
- A reported visual/UI bug in Lattice → ask for the DOM class, `window.__latticeDebug` output, or `harness-snapshot` curl BEFORE reading code
- Claiming a fix works without end-to-end validation in the real running product
- Debugging races, async ordering, client/server sequencing, queues, retries, or state-machine transitions
- User asks to stress-test a proposed fix for a state/race bug

## Evidence-first posture

Before converging on a diagnosis:

- Be explicit about what you know, what you're inferring, what you're uncertain about, and what assumptions you're making
- Resolve factual or checkable unknowns by inspecting code, docs, data, MCP tools, or the running app before asking the user
- Ask clarifying questions only when the answer would change strategy, requires a user preference/judgment call, or cannot be verified directly
- Acknowledge ambiguity and complexity rather than simplifying too quickly
- When analyzing metrics or analytics data, default to skepticism about organic attribution — investigate non-organic sources (bots, mirrors, CI pipelines, crawlers) before concluding real adoption/usage
- When a reference doc topic is cited (model landscape, infrastructure, project context), read the linked file before concluding — persisted docs are the source of truth; training knowledge is stale

## When unexpected behavior shows up

An error you didn't anticipate, a command failing when it shouldn't, data not matching assumptions, a tool behaving unexpectedly, something that "should" exist missing:

1. **Explain the gap**: "I expected X, but got Y"
2. **State your best current hypothesis or uncertainty**
3. **Continue investigating by default** — gather evidence, isolate the cause

Stop and ask for direction only if the next step would be destructive, irreversible, security/privacy-sensitive, require new credentials/access, materially change scope/strategy, or commit the user to a significant choice. Do NOT silently work around the issue or add a hidden fallback.

## Workflow

### 1. Clarify the symptom

If the report is ambiguous, ask targeted questions:
- What did you do? (trigger action)
- What did you expect? (expected behavior)
- What happened instead? (actual behavior)
- Does it persist or resolve? (on refresh, navigation, time)
- Intermittent or consistent?

**For visual/UI bugs in Lattice:** ask for the DOM class, `window.__latticeDebug` output, or `harness-snapshot` curl before diving into code. Symptom descriptions are ambiguous at the DOM level — burning turns reasoning top-down from English is the anti-pattern.

If the report is clear, skip straight to investigation.

### 2. Investigate

Trace the bug from symptom to root cause:

- **Start with the rendering path** — what component/prop/state drives the visible symptom?
- **Trace upstream** — what sets that state? What events/callbacks modify it?
- **Identify the invariant violation** — what assumption is broken?
- **Check boundaries** — server/client handoff, SSE events, state transitions, timing/races

Use the Explore agent for broad "how does X work" questions. Use direct file reads for targeted code inspection once you know where to look.

**For race / state-machine / async-ordering bugs**, switch to hand-computation: execute the system manually, step by step, writing down concrete state at every transition. Maintaining state across steps forces contradictions to surface; abstract review does not. This is especially critical when a bug was fixed once and regressed — the mental model used for the first fix is wrong or incomplete, and more review won't find it.

### 3. State diagnosis with confidence

Be explicit:
- **Root cause**: what specifically is wrong and why
- **Confidence**: percentage + what would raise/lower it
- **Trigger conditions**: when does the bug manifest
- **Why intermittent** (if applicable): what race/timing/state makes it inconsistent

### 4. Write reproduction tests

Write tests that **PASS by asserting the buggy behavior**. These become red tests for the fix and regression tests after.

Location: `tests/unit/web/chat/` in lattice-orchestrator, following existing patterns:
- Use vitest (`import { describe, it, expect } from 'vitest'`)
- Import real functions from source — don't mock the code under test
- If a function isn't exported, inline a copy with a comment noting the source
- Test the actual data flow: realistic inputs → function → assert buggy output
- Name tests descriptively: `BUG: <what goes wrong>`

**For tests that depend on event streams, protocol data, or multi-step runtime behavior**: prefer recording real sessions as fixtures over hand-constructed synthetic event sequences. Real recordings capture timing, ordering, and interleaving that synthetic fixtures miss. Fall back to synthetic only for states that can't be triggered naturally (error injection, edge timing).

### 5. Verify tests pass

Run `pnpm vitest run <test-file>` and confirm all tests pass (proving the bugs exist).

### 6. Validate in the real product

For user-facing or end-to-end changes — especially UI, auth, permissions, browser behavior, logging, external integrations — validate behavior in the real running product before claiming success. Chrome MCP is the primary tool for browser-facing behavior; use it proactively rather than relying on code inspection alone. For backend work, use live runtime checks.

If live validation is blocked, state what you could not verify and why.

### 7. Summarize

End with a structured summary:

**Root cause**: ...
**Confidence**: X%
**Trigger**: ...
**Affected code paths**: file:line references
**What the fix needs to address**: ...

## Further investigation guidance

- **Regression checks first.** When fixing a regression, add the smallest meaningful regression check (test, preflight, or reproducible manual path). If feasible, prove the check fails without the fix before declaring the bug closed.
- **MCP integrations are a frequent failure source.** When investigating session hangs, tool errors, or performance issues, check MCP server health (process count, config versions, startup behavior) early before diving into application code.
- **Environment causes before code bugs.** When tools or integrations fail locally, consider environment causes (missing env vars, token scopes, network config, K8s-only services) before assuming a code bug — local/production divergence is a common root cause.
- **Broader systemic issues.** When a specific investigation reveals a broader pattern (noisy logs, inconsistent architectures, stale docs), surface it and ask whether to broaden into a full audit. This is a common and welcome pivot.

## Rules

- **No fixes.** Diagnose and prove only. The user decides when and how to fix.
- **No speculating past your evidence.** If you can't trace it, say so and state what you'd need to verify.
- **Test the actual code paths**, not simplified models. Import real functions.
- **State what you checked and ruled out**, not just what you found.
- **If you hit low confidence (<60%)**, say so and propose what investigation would raise it.
- **Never silently work around.** If the root cause is elusive and a workaround is tempting, surface that, state the tradeoff, and wait for explicit permission.
- **"Flaky" is a non-diagnosis.** Investigate every failure; explain the root cause; fix it.
