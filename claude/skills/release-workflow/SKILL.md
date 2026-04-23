---
name: release-workflow
description: Publish a package or cut a release. Use when user says "publish", "release", "cut a release", "ship a version", or wants to run the release workflow. Enforces preflight-first, permission-gated publishing.
---

# Release workflow

Jason's rule: **publishing requires the same explicit permission as committing, and preflight must pass.**

## Preflight-first

1. Run the full preflight/CI/test suite before doing anything publish-shaped.
2. **If any check fails: halt.** Report the failure, diagnose the root cause, and fix before retrying. Never publish over failures.
3. Re-run preflight after any fix to confirm green.

## Clean-diff discipline

- If the diff is entangled (multiple logical changes bundled), use `git add -p` to split into conceptually clean commits before publishing.
- Prefer small, logically grouped commits over one large undifferentiated change.

## Gate the final publish step

- After preflight is green and commits are clean, **stop and ask for explicit user approval** before running the actual publish/release command.
- Do not push to a remote or trigger a non-local deployment without explicit permission — same bar as committing.

## When things fail mid-publish

- Don't retry blindly or add workarounds to get past failures.
- Diagnose the root cause, fix it, re-run preflight, and ask before retrying the publish step.
