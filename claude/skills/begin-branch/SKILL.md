---
name: begin-branch
description: Create a feature branch and first commit. Use when user says "let's commit", "start a branch", "let's save this", or has reached a milestone and wants to formalize work.
---

# Begin Branch

Create a branch and first commit to formalize work in progress.

## Workflow

1. **Check current branch**
   - If on `main`: proceed to step 2
   - If on feature branch: ask user — "You're on `jason/feature/xyz`. Use this branch, or start fresh from main?"
     - If start fresh: `git checkout main && git pull`

2. **Infer from context** and propose options:
   ```
   Based on the work so far, here are some options:

   Branch: jason/feature/session-filtering
   Commit: [session-filtering] add date range picker and filter controls

   Branch: jason/feature/date-filters
   Commit: [date-filters] add date range picker and filter controls

   Which works, or suggest your own?
   ```

3. **After confirmation**: create branch and commit

## Branch format

`jason/{type}/{description}`

Examples of types: `feature`, `fix`, `refactor`

## Commit format

`[tag] lowercase description of actual changes`

- Tag reflects work area
- Description says what changed
- No period at end

## Rules

- Always propose and confirm before creating
- Offer 2-3 options when context allows
- Never commit directly to main
