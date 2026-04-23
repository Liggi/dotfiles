---
name: diagnose
description: Investigate and prove UI/frontend bugs in Lattice with reproduction tests. Use when user reports a bug symptom, says "diagnose", "investigate", "why is X happening", or describes unexpected behavior. Does NOT fix — only investigates, proves, and documents.
---

# Diagnose

Investigate a reported bug, trace the root cause through code, prove it with tests, and document findings. No fixes.

## When to Use

- User describes a bug symptom ("X is happening", "Y is broken", "seeing Z after doing W")
- User says "diagnose", "investigate", "what's causing this"
- Unexpected UI behavior that needs root cause analysis

## Workflow

### 1. Clarify the Symptom

If the report is ambiguous, ask targeted questions:
- What did you do? (trigger action)
- What did you expect? (expected behavior)
- What happened instead? (actual behavior)
- Does it persist or resolve? (on refresh, navigation, time)
- Intermittent or consistent?

If the report is clear, skip straight to investigation.

### 2. Investigate

Trace the bug from symptom to root cause:

- **Start with the rendering path** — what component/prop/state drives the visible symptom?
- **Trace upstream** — what sets that state? What events/callbacks modify it?
- **Identify the invariant violation** — what assumption is broken?
- **Check boundaries** — server/client handoff, SSE events, state transitions, timing/races

Use the Explore agent for broad "how does X work" questions. Use direct file reads for targeted code inspection once you know where to look.

### 3. State Diagnosis with Confidence

Be explicit:
- **Root cause**: what specifically is wrong and why
- **Confidence**: percentage + what would raise/lower it
- **Trigger conditions**: when does the bug manifest
- **Why intermittent** (if applicable): what race/timing/state makes it inconsistent

### 4. Write Reproduction Tests

Write tests that **PASS by asserting the buggy behavior**. These become red tests for the fix and regression tests after.

Location: tests/unit/web/chat/ in lattice-orchestrator, following existing patterns:
- Use vitest (import { describe, it, expect } from 'vitest')
- Import real functions from source — don't mock the code under test
- If a function isn't exported, inline a copy with a comment noting the source
- Test the actual data flow: realistic inputs -> function -> assert buggy output
- Name tests descriptively: BUG: <what goes wrong>

### 5. Verify Tests Pass

Run pnpm vitest run <test-file> and confirm all tests pass (proving the bugs exist).

### 6. Summarize

End with a structured summary:

**Root cause**: ...
**Confidence**: X%
**Trigger**: ...
**Affected code paths**: file:line references
**What the fix needs to address**: ...

## Rules

- **No fixes.** Diagnose and prove only. The user decides when and how to fix.
- **No speculating past your evidence.** If you can't trace it, say so and state what you'd need to verify.
- **Test the actual code paths**, not simplified models. Import real functions.
- **State what you checked and ruled out**, not just what you found.
- **If you hit low confidence (<60%)**, say so and propose what investigation would raise it.
