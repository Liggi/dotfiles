---
name: circleci
description: Debug CircleCI failures for GitHub PRs. Use when CI checks fail, user asks about build failures, or needs to diagnose why a PR isn't passing. Fetches actual error logs from CircleCI API.
---

# CircleCI Debugging

Diagnose CI failures by fetching actual build logs from CircleCI.

## When to Use

- PR checks are failing
- User asks "why is CI failing?"
- Need to understand build/test errors
- Investigating flaky tests

## Prerequisites

CircleCI CLI must be configured with a token at `~/.circleci/cli.yml`:
```yaml
token: CCIPAT_xxx...
```

## Workflow

### 1. Get failing checks for a PR

```bash
gh pr checks <PR_NUMBER> --repo <owner/repo>
```

This shows which jobs failed and their CircleCI URLs (e.g., `https://circleci.com/gh/org/repo/12345`).

### 2. Extract job number from URL

The job number is the last segment of the CircleCI URL (e.g., `12345` from `.../repo/12345`).

### 3. Fetch job details

```bash
CIRCLE_TOKEN=$(grep "^token:" ~/.circleci/cli.yml | cut -d' ' -f2)
curl -s "https://circleci.com/api/v2/project/gh/<owner>/<repo>/job/<job_number>" \
  -H "Circle-Token: $CIRCLE_TOKEN" | jq '.name, .status'
```

### 4. Find failed steps

```bash
curl -s "https://circleci.com/api/v1.1/project/github/<owner>/<repo>/<job_number>?circle-token=$CIRCLE_TOKEN" \
  | jq '.steps[] | select(.actions[].failed == true) | {name: .name, status: .actions[].status}'
```

### 5. Get actual error output

```bash
OUTPUT_URL=$(curl -s "https://circleci.com/api/v1.1/project/github/<owner>/<repo>/<job_number>?circle-token=$CIRCLE_TOKEN" \
  | jq -r '.steps[] | select(.actions[].failed == true) | .actions[].output_url')

curl -s "$OUTPUT_URL" | jq -r '.[] | .message' | tail -100
```

## Common Failure Patterns

### Unresolved reference / compilation error
- **Symptom**: `Unresolved reference 'foo'`
- **Cause**: Often a dependency version issue - function exists in main but hasn't been released
- **Fix**: Check if the required code is in a published version of the dependency

### Test failures
- **Symptom**: `FAILED` in test output
- **Cause**: Could be flaky test, environment difference, or actual regression
- **Fix**: Run tests locally first, check for environment-specific issues

### Dependency resolution
- **Symptom**: `Could not resolve` or `Module not found`
- **Cause**: Version doesn't exist in registry, or registry auth issue
- **Fix**: Verify version is published, check registry credentials in CI context

## API Reference

**V2 API** (job metadata):
```
GET https://circleci.com/api/v2/project/gh/{org}/{repo}/job/{job_number}
Header: Circle-Token: <token>
```

**V1.1 API** (detailed step output):
```
GET https://circleci.com/api/v1.1/project/github/{org}/{repo}/{job_number}
Query: circle-token=<token>
```

## Tips

- The v2 API gives job metadata; v1.1 API gives step-level details and output URLs
- Output URLs are pre-signed and time-limited - fetch them fresh each time
- For Gradle builds, look for `FAILED` or `error:` in the output
- Check `depversions.gradle.kts` or equivalent when seeing unresolved references
