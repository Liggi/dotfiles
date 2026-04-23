---
name: create-pr
description: Create a GitHub pull request. Use when user says "create a PR", "open a pull request", "ready for PR", or wants to submit work for review.
---

# Create PR

Create a pull request with title and description matching Jason's style.

## Workflow

1. **Gather context**
   - `git log origin/main..HEAD --oneline` — commits on this branch
   - `git diff origin/main..HEAD --stat` — files changed
   - `gh search prs --author "@me" --limit 10 --json title,body,repository` — recent PRs across all repos for style

2. **Study PR patterns** from the last ~10 PRs:
   - Title format and length
   - Description structure (bullets, headers, etc.)
   - Level of detail
   - How commits map to PR description

3. **Propose title + description**:
   ```
   Based on your commits and recent PR style:

   Title: Conversation Analysis - add date filtering

   Description:
   ## What changed
   - Add date range picker component
   - Connect filters to backend query params

   Thoughts? Want to adjust anything?
   ```

4. **Iterate** until user approves

5. **Create PR**:
   - Push branch if needed
   - `gh pr create --title "..." --body "..."`
   - Return PR URL

## Rules

- Look at multiple recent PRs, not just one
- Match the user's actual style, not a template
- Keep descriptions concise — match what user typically writes
- Ask before creating
