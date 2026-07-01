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

So your job when you open a PR is not to prove the code is correct. It is to **surface whatever
genuinely needs their judgment — often that's little, sometimes nothing, occasionally a few things —
and never make them dig for it.** A small, single-purpose change with its risky choice flagged up
front costs the reviewer seconds; a large, mixed change that buries a sharp edge costs them twenty
minutes of hunting, or they miss it.

**Write for a reviewer who wasn't in your session.** You have context they don't — the task, the
conversation, the paths you explored, the decisions you made along the way. They see only the diff.
So everything you write — description, review notes, inline comments — has to stand on its own from
the diff: no "as we discussed", no reference to a decision or a detour the reviewer never saw.

Read these reference files when you reach the matching step:

| When | Reference |
|---|---|
| Checking your change against what reviewers here flag | `references/house-rules.md` — patterns this team comments on |
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
- **When it's clearly multi-PR or crosses repos, surface the plan and get a nod before you code — in
  plain language the person can actually judge.** The person driving you may not be an engineer, so
  don't lean on repo names or architecture jargon (not "I'll split this contracts → backend → mobile").
  Explain the sequence and the trade-off in terms they can weigh: "I'll ship the part you can see first
  so it's easy to review, then wire up the behind-the-scenes piece in a second PR — good that way?"
  Don't silently produce one giant PR, and don't silently ship partial work either — the human decides
  the breakdown with you.
- **As you work, keep concerns separated.** Never mix a refactor with a behavior change (do the move in
  one PR, the behavior in another, so the reviewer can verify "this part is a pure rename" in one cheap
  judgment). Never mix formatting with logic. If the change grows past its plan mid-way, stop and
  re-decide the split rather than letting it sprawl.
- **Commit in clear steps — the history is part of the narrative.** Group commits so each is one
  logical step and a reviewer can read the change commit-by-commit, rather than dumping the whole thing
  into a single opaque commit. Each message says, in a line, what that step does.
- **If a change genuinely cannot be split,** say so explicitly in the review notes (step 3), so the
  reviewer knows the size is a knowing trade-off, not an accident.

## 2. Before you open it — review your own diff first

Read your whole diff as if you were the reviewer and you don't trust the author.

- **Strip the noise** — dead code, commented-out experiments, leftover debug, notes-to-self,
  unrelated churn. Every line of noise is attention stolen from the real change.
- **Read `references/house-rules.md` and go through the applicable rules.** These are the things
  reviewers here flag repeatedly — mined from real review history and tagged by how often each recurs.
  Check your diff against the ones that apply, starting with the `[load-bearing]` ones (performance/scale,
  reversibility, decomposition, diff-noise), and fix what you can. Not every rule applies to every change.
- **Get the machines green where you can** — lint, format, tests, codegen — so the reviewer never
  spends a comment on something a tool could have caught. If something genuinely can't pass yet (e.g. it
  depends on a contract or shared-library change that isn't merged), say so in the review notes rather
  than leaving the reviewer to wonder why CI is red.

## 3. Write it up — narrative, then the review notes

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

Run this self-interrogation to fill it (the specifics of *what* counts as risky live in the
house-rules):
- Did I **make something hard to change** that a reviewer might want kept reversible? → Decisions.
- Did I **work around** a crash, a sharp edge, or something I didn't fully understand? → Workarounds, named plainly. Never describe a workaround as a clean feature.
- Is there a part where I'm **guessing** it's safe or performant but didn't verify? → Couldn't verify.
- Is there one **load-bearing choice** the whole change rests on? → Look here first.

If the honest answer to all of these is "no" — say so in one line. That itself is a useful signal:
it tells the reviewer this one is safe to read fast.

**Inline comments — annotate the *genuinely* non-obvious, for the reviewer.** Only where a reviewer
would land on a specific line and truly think *why did they do that* — not everywhere, and not the
merely-normal. Leave a **GitHub inline comment on the diff** — a PR review comment, not a code comment:
"did this instead of X because Y", "looks redundant but it's load-bearing because…", "unsure about
this line, worth a look." Write it for a fresh reviewer who wasn't in your session — it has to make
sense from the diff alone, with no reference to decisions, discussion, or exploration they never saw.
It pre-empts the exact question that would otherwise cost a round-trip, and unlike a code comment it
doesn't live in the codebase forever. Two or three spots at most.
