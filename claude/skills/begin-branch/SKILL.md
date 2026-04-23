---
name: begin-branch
description: Git/commit workflow — invoke before any `git add`, `git commit`, `git push`, or deploy command. Never commits without explicit user permission in the current session. Covers pre-flight worktree checks, branch creation, commit message authorship from the full staged diff, and directory-awareness checks before path-sensitive commands.
---

# Begin Branch

Git/commit workflow. Covers the full lifecycle — pre-flight checks, branching, worktree hygiene, commit message authorship, and the never-commit-without-permission rule.

## The ironclad rule

**Never commit, push, or trigger a non-local deployment without explicit permission in the current session.** Same bar for commits, remote pushes, and environment-changing deploys. When work looks done, ask *"ready to commit?"* and wait for an explicit yes. Type checks passing is not approval. "Looks good" on the code is not approval to commit.

## When to invoke this skill

Invoke as a mandatory gate — not a soft suggestion — before any of the following:

- Running `git add`, `git commit`, or `git push`
- Running any deploy or publish command
- Starting a new feature branch from a milestone
- At session start or before any broad edit — check `git status` first to surface unrelated changes
- Before running path-sensitive or repo-specific commands — confirm `cwd`

## Pre-flight checks (every time)

1. **Worktree hygiene.** Run `git status`. If the worktree has unrelated changes, don't mix them in — preserve them and ask whether to separate via branch, stash, or distinct commit. Prefer small, logically grouped commits; keep the diff conceptually clean.

2. **Directory awareness.** Confirm `cwd` is what you expect before any repo-specific or potentially destructive command. Don't ritualistically run `pwd` before every `cd`, but do verify when it matters.

3. **Read the full staged diff.** When writing a commit message, run `git diff --staged` first. Describe the whole change being committed, not just the last edit you made.

## Branch workflow (when starting fresh work)

1. **Check current branch.**
   - If on `main`: proceed to step 2
   - If on a feature branch: ask — *"You're on `jason/feature/xyz`. Use this branch, or start fresh from main?"*
     - If start fresh: `git checkout main && git pull`

2. **Infer from context and propose options:**
   ```
   Based on the work so far, here are some options:

   Branch: jason/feature/session-filtering
   Commit: [session-filtering] add date range picker and filter controls

   Branch: jason/feature/date-filters
   Commit: [date-filters] add date range picker and filter controls

   Which works, or suggest your own?
   ```

3. **After confirmation**: create the branch and make the first commit.

## Branch format

`jason/{type}/{description}` — common types: `feature`, `fix`, `refactor`, `cleanup`, `chore`

## Commit message format

- **One-liner**: `[category] lowercase description`
- **Check recent git history first** (`git log --oneline -10`) and match existing tag patterns when the work is related
- For new features, use descriptive feature tags (`[auth]`, `[search]`, `[ui]`, `[claude]`, `[lattice]`) **not** generic `[feat]`
- For common changes, use standard tags: `[bugfix]`, `[infra]`, `[config]`, `[docs]`, `[tooling]`, `[cleanup]`
- Describe the **conceptual shape** of the work, not just the technical action
- No period at end
- Claude Code attribution is blocked deterministically by `commit-attribution-hook.sh` — don't include attribution lines

## Rules

- **Always propose and confirm** before creating a branch or commit — offer 2–3 options when context allows
- **Never commit directly to main** from the default workflow. (Lattice is the exception; that rule lives in the Lattice repo's own `CLAUDE.md`.)
- **Never use `git add -A` or `git add .`** — stage specific files by name to avoid accidentally including credentials, large binaries, or unrelated changes
- **Never `--amend`** a commit after a pre-commit hook failure — the commit did NOT happen, so `--amend` would modify the PREVIOUS commit. Fix the underlying issue, re-stage, and create a NEW commit
- **Never skip hooks** (`--no-verify`) unless the user explicitly requests it
- **Never force-push** to main/master; warn loudly if the user requests it
- **Never push** unless the user explicitly asks you to
