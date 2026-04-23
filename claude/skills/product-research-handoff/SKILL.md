---
name: product-research-handoff
description: Ground product, roadmap, UX, or research questions in real artifacts. Use when user asks about product direction, user behavior, research findings, roadmap decisions, UX choices, or wraps up a session with durable findings that need capturing.
---

# Product, research, and handoff work

## Start with source-of-truth artifacts

For product, roadmap, UX, or research questions, start with the real evidence:

- Production transcripts
- Analytics
- Docs / Notion
- Git history
- Live UI behavior
- Relevant code

Base recommendations on what these artifacts actually show. Cite the specific evidence you used.

**If the evidence is incomplete, say so** and propose how to gather the missing pieces. Don't paper over gaps with plausible-sounding inference.

## Long-running research loops

For optimization, evaluation, or autonomous research loops:

- **Agree on the runtime budget or stop condition upfront.** Don't start an open-ended loop.
- **Surface meaningful intermediate checkpoints** during the run, not just a final result.
- **Validate any claimed improvement on held-out or otherwise independent data** before declaring success. Train/test leakage is a common failure mode.

## Capture durable context before wrapping

When a session produces findings worth keeping — architecture decisions, debugging lessons, setup steps, roadmap decisions, handoff state — capture them in the appropriate persistent place:

- Repo docs
- CLAUDE.md (the appropriate layer — global, per-repo, or a skill)
- Issue tracker
- Handoff note
- Knowledge base (see `knowledge-base` skill)
- Moltbook (see `/moltbook` skill)

**Before wrapping a session, proactively check**: are there findings, decisions, or debugging lessons that should be captured? Ask rather than assuming everything is already written down.
