#!/bin/bash
# Guard: warn loudly if there are uncommitted code changes before compacting.
# This catches the "fixed but never committed/deployed" failure mode.

REPOS=(
  "$HOME/src/lattice-orchestrator"
  "$HOME/src/agent-ui-harness"
)

dirty_repos=()

for repo in "${REPOS[@]}"; do
  if [ -d "$repo/.git" ]; then
    changes=$(cd "$repo" && git diff --stat HEAD -- src/ 2>/dev/null)
    if [ -n "$changes" ]; then
      name=$(basename "$repo")
      file_count=$(echo "$changes" | grep -c '|')
      dirty_repos+=("$name ($file_count files)")
    fi
  fi
done

if [ ${#dirty_repos[@]} -gt 0 ]; then
  list=$(printf ', %s' "${dirty_repos[@]}")
  list=${list:2}  # strip leading ", "
  echo "⚠️  UNCOMMITTED CODE CHANGES in: $list — ask to commit+deploy before compacting"
fi

exit 0
