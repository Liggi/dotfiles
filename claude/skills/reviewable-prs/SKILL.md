---
name: reviewable-prs
description: >
  How to ship a pull request that is cheap for a human to review. Use this skill whenever you are
  about to start, or are working on, a coding task that will end in a PR — and again when you finish
  the work and write the PR up. This includes any change to an app, backend, or shared library that
  a teammate will review before it merges. Trigger when the user says "open a PR", "ship this",
  "write the PR", "make a pull request", "this is ready for review", "create the PR description", or
  when you are about to run `git commit` / `gh pr create` on real work. It also applies from the
  moment a codeable task begins, because the most important reviewability decisions — how big the
  change is and whether it mixes concerns — are made while you work, not at the end. If a human is
  going to review what you wrote, this skill applies.
---

# Reviewable PRs

> A practical guide for shipping changes a human can review fast. Every rule here exists to spend
> the reviewer's attention well.

## The one idea

A PR is not a delivery of code — it is a **request for someone's attention**. Your reviewer has a
fixed budget of it: roughly an hour and a few hundred lines before they stop verifying and start
rubber-stamping. The code itself is usually fine — automated review (Codex/CI) catches the bugs.
What a human spends their scarce attention on is **judgment**: is this the right shape, can we change
it later, will it hold up under real use, is anything here risky.

So your job when you open a PR is not to prove the code is correct. It is to **surface the one thing
worth looking at, and not make the reviewer dig for it.** A small, single-purpose change with the
risky decision flagged up front costs the reviewer seconds. A large, mixed change that buries its one
sharp edge costs them twenty minutes of hunting — or they miss it.

Read these reference files when you reach the matching step:

| When | Reference |
|---|---|
| Writing the PR description / unsure if a decision is worth flagging | `references/examples.md` — a real good-vs-bad pair |
| Self-scoring before you request review | `references/rubric.md` — the four dimensions a reviewer feels |

---

## 1. Before you write code — decide the PR breakdown

The biggest reviewability decision is **size and scope**, and it is made *before* you write the
code, not when you write the description. You cannot make a 2,000-line mixed-concern change easy to
review after the fact — by then the work is done and splitting it is expensive or impossible. So the
first thing you do, before coding, is decide whether this is one PR or several.

- **The test for "one PR": a reviewer can say what it does in a sentence.** One logical, self-contained
  change. If describing it takes "and" twice, it is probably two PRs.
- **If the task is inherently bigger — plan a sequence of small PRs, up front.** A change that touches
  multiple layers or repositories (e.g. contracts → backend → mobile), or that will clearly run past a
  few hundred lines, should be broken into a sequence where each PR is independently reviewable and
  builds on the last. Land the foundation first, then build on it. Decide the seams *before* you start,
  not after.
- **When it's clearly multi-PR or crosses repos, surface the plan to the person and get a nod before
  you code.** Say "this is going to be roughly N PRs — first X, then Y, then Z; that lets each be
  reviewed on its own. Good to go this way?" Don't silently produce one giant PR, and don't silently
  ship partial work either — the human decides the breakdown with you. This is the single most valuable
  thing you can do for a hard change, and it has to happen before the code exists.
- **As you work, keep concerns separated.** Never mix a refactor with a behavior change (do the move in
  one PR, the behavior in another, so the reviewer can verify "this part is a pure rename" in one cheap
  judgment). Never mix formatting with logic. If the change grows past its plan mid-way, stop and
  re-decide the split rather than letting it sprawl.
- **Commit in clear steps — the history is part of the narrative.** A reviewer often reads a PR
  commit-by-commit, so make each commit one logical step with a short imperative message
  (`Add breathing-pace engine`, not `wip`, `fixes`, or `address feedback`). Don't squash the whole
  change into one opaque commit, and don't leave a trail of `fix2` noise — reshape the history so the
  steps tell the story of how the change was built.
- **If a change genuinely cannot be split,** say so explicitly in the review notes (step 4), so the
  reviewer knows the size is a knowing trade-off, not an accident.

## 2. The four principles — how this team likes things built

These are the things a human reviewer comments on over and over. Apply them as you write the code, so
the reviewer never has to.

1. **Reversible by default.** Anything a user sees or feels — copy, animations, thresholds, which
   options exist, whether a feature is on — should be controllable from the backend or a feature flag
   (Statsig), not baked into a release. The test: *if we wanted to change this next week, would we
   need an app release?* If yes, and it plausibly will change, make it backend-driven. If you must
   hardcode it, flag that choice in the review notes — don't let it pass silently.

2. **Single responsibility.** A widget, class, or function does one thing. If a widget is holding
   state *and* branching on type *and* firing analytics, split it and pull the logic into a
   controller, so the logic is testable on its own and the render code stays readable. "This file is
   doing too much" is a comment you can pre-empt.

3. **Performance on real data, not your data.** Assume your change runs on a power user: a long
   history, hundreds of items, a slow network. Anything that grows with usage must **lazy-load** —
   never load a whole collection at once to render a list. The common failure is code that's instant
   on a test account and janks or crashes on someone with 50+ weeks of history. You won't always know
   which areas are performance-sensitive; when a change touches a list, a feed, or a history, assume
   it is.

4. **No notes-to-self.** Strip comments that narrate what the next line does, or restate what the PR
   description already says — this team removes them as noise. Keep a comment only when it explains a
   non-obvious *why* a reader cannot get from the code itself (a guard that exists for a subtle
   reason, the rationale behind a heuristic). "A note from Claude to itself" is the exact thing
   reviewers call out; don't ship it. When there *is* a non-obvious "why" the reviewer will wonder
   about, prefer a **GitHub inline comment on the PR** (step 4) — it speaks to the reviewer and doesn't
   ship in the codebase — over a code comment that lives there forever.

## 3. Before you open it — review your own diff first

Read your whole diff as if you were the reviewer and you don't trust the author.

- **Strip the noise** — dead code, commented-out experiments, leftover debug, notes-to-self,
  unrelated churn. Every line of noise is attention stolen from the real change.
- **Run the four principles against it** — did you bake anything in, overstuff a widget, eager-load a
  growing collection, leave narration comments? Fix what you can.
- **Get the machines green first** — lint, format, tests, codegen. The human reviewer should never
  spend a comment on something a tool could have caught.

## 4. Write it up — narrative, then the review notes

The description is where you hand over what the diff can't show: *why*.

**Narrative — what, why, where.** Three short parts: what this change does, *why* it's being made
(the problem, not a restatement of the diff), and where to look first. Order it as a reading path, so
the reviewer reconstructs your intent without reading every line. Don't restate the code in prose.

**Review notes — surface, don't make them dig.** This is the part that earns the skill its name. Be
**ruthlessly selective**: most changes are fine, and a notes section that always lists five things
becomes the noise you're trying to avoid. Surface only what genuinely deserves the reviewer's scarce
attention. The shape:

```
## Review notes
Look here first: <the one place attention is best spent — or "nothing notable, small self-contained change">
Decisions you might disagree with: <load-bearing or risky choices, with the alternative you rejected — omit if none>
Couldn't verify: <anything you couldn't test or confirm — runtime behavior, performance under load — omit if none>
Workarounds: <any hack and why you took it; if you worked around a crash or a sharp edge, say so plainly — omit if none>
```

Run this self-interrogation to fill it, keyed to the four principles:
- Did I **bake something in** that should be backend-driven? → Decisions.
- Did I **work around** a crash, a sharp edge, or something I didn't fully understand? → Workarounds, named plainly. Never describe a workaround as a clean feature.
- Is there a part where I'm **guessing** it's safe or performant but didn't verify? → Couldn't verify.
- Is there one **load-bearing choice** the whole change rests on? → Look here first.

If the honest answer to all of these is "no" — say so in one line. That itself is a useful signal:
it tells the reviewer this one is safe to read fast.

**Inline comments — annotate the non-obvious, *for the reviewer*.** Where a reviewer would land on a
specific line and think *why did they do that*, leave a **GitHub inline comment on the diff** — a PR
review comment, not a code comment. "Did this instead of X because Y," "looks redundant but it's
load-bearing because…," "unsure about this line, worth a look." It pre-empts the exact question that
would otherwise cost a round-trip, and unlike a code comment it's addressed to the reviewer and doesn't
live in the codebase forever — this is where the "why" that doesn't belong in the code goes. Use it for
the two or three spots that genuinely need it, not every file.

---

## Why this works (one paragraph)

Everything above is one move: move the cost from the reviewer to you, the author, because you have
context they don't. You know *why* you made each choice, what you were unsure about, and where the
risk is — while you're writing it. The reviewer has to reconstruct all of that from the diff alone,
which is the expensive part and the part they most often get wrong. Surfacing your own questionable
decisions isn't a confession — it's the single highest-leverage thing you can do, because it puts the
reviewer's attention exactly where it's worth spending and nowhere else.
