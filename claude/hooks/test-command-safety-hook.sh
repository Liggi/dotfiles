#!/bin/bash
# Test harness for command-safety-hook.sh.
# Runs a curated set of cases representing patterns from Jason's actual session
# friction, plus legitimate cases that must not be blocked.
#
# Usage: bash test-command-safety-hook.sh [path-to-hook]

set -u

HOOK="${1:-$(dirname "$0")/command-safety-hook.sh}"

if [ ! -x "$HOOK" ]; then
  echo "Hook not executable at $HOOK" >&2
  exit 2
fi

PASS=0
FAIL=0
FAILS=()

case_json() {
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({
  "tool_name": "Bash",
  "cwd": sys.argv[2],
  "tool_input": {"command": sys.argv[1]}
}))
PY
}

run_case() {
  local name="$1" expected="$2" command="$3" cwd="${4:-/Users/jasonliggi/src/lattice-orchestrator}"
  local out decision
  out=$(case_json "$command" "$cwd" | "$HOOK" 2>/dev/null)
  decision=$(printf '%s' "$out" | jq -r '.decision' 2>/dev/null)
  if [ "$decision" = "$expected" ]; then
    PASS=$((PASS+1))
    printf '  \033[32mPASS\033[0m  %s\n' "$name"
  else
    FAIL=$((FAIL+1))
    FAILS+=("$name (expected=$expected got=$decision out=$out)")
    printf '  \033[31mFAIL\033[0m  %s — expected=%s got=%s\n' "$name" "$expected" "$decision"
    printf '         out=%s\n' "$out"
  fi
}

echo "Running command-safety-hook tests against: $HOOK"
echo
echo "## Rule 1 — broad find"
run_case "block: find / -name sc"                  block   "find / -maxdepth 6 -name sc"
run_case "block: find ~ -name foo"                 block   "find ~ -name history.db"
run_case "block: find /Users/jasonliggi"           block   "find /Users/jasonliggi -name '.mcp.json'"
run_case "block: find ~/src"                       block   "find ~/src -maxdepth 3 -iname '*proj-slingshot*'"
run_case "allow: scoped find under repo"           approve "find /Users/jasonliggi/src/slingshot-ai/slingshot-analyst/src -name '*.ts'"
run_case "allow: find . -name *.md"                approve "find . -maxdepth 2 -name '*.md'"

echo
echo "## Rule 2 — fd"
run_case "block: fd unscoped from ~/src"           block   "fd proactive"               "/Users/jasonliggi/src"
run_case "block: fd with explicit ~/src"           block   "fd -t f history.db ~/src"
run_case "block: fd with /Users/jasonliggi"        block   "fd . /Users/jasonliggi"
run_case "allow: fd with scoped path arg"          approve "fd proactive src/lib/slack" "/Users/jasonliggi/src/slingshot-ai/slingshot-analyst"
run_case "allow: fd from inside a specific repo"   approve "fd proactive"               "/Users/jasonliggi/src/slingshot-ai/slingshot-analyst"
run_case "allow: fd -t f scoped"                   approve "fd -t f history.db /Users/jasonliggi/src/slingshot-ai/slingshot-analyst"

echo
echo "## Rule 3 — ls -R"
run_case "block: ls -R from repo root no target"   block   "ls -R"             "/Users/jasonliggi/src/lattice-orchestrator"
run_case "block: ls -R ."                          block   "ls -R ."
run_case "block: ls -R ~/src"                      block   "ls -R ~/src"
run_case "allow: ls -R src/app/api | head"         approve "ls -R src/app/api | head -50"
run_case "allow: ls -la (no -R)"                   approve "ls -la /Users/jasonliggi/src"

echo
echo "## Rule 4 — long sleeps and polling"
run_case "block: sleep 60"                         block   "sleep 60"
run_case "block: sleep 180 && capture"             block   "sleep 180 && tmux capture-pane -t pulse-cal -p"
run_case "block: until grep DONE; do sleep 30"     block   "until grep -q DONE log; do sleep 30; done"
run_case "block: while running; do sleep 15"       block   "while ps -p \$PID > /dev/null; do sleep 15; done"
run_case "allow: short sleep"                      approve "sleep 5 && cat log.txt"
run_case "allow: sleep inside tmux new-session"    approve "tmux new-session -d -s job 'sleep 600 && echo done'"
run_case "allow: sleep paired with ScheduleWakeup" approve "sleep 60 # paired with ScheduleWakeup elsewhere"

echo
echo "## Override"
run_case "allow: override comment on broad find"   approve "find ~/src -name '*.md' # claude-allow-unsafe-command: deliberate audit"
run_case "allow: override env var on long sleep"   approve "CLAUDE_ALLOW_UNSAFE_COMMAND=1 sleep 120"

echo
echo "## Common legitimate commands must not be blocked"
run_case "allow: git status"                       approve "git status -sb"
run_case "allow: pnpm install"                     approve "pnpm install"
run_case "allow: sqlite query"                     approve "sqlite3 ~/.lattice/session-info.db 'SELECT COUNT(*) FROM sessions'"
run_case "allow: cat with head"                    approve "cat ~/CLAUDE.md | head -40"
run_case "allow: rg pattern in repo"               approve "rg 'foo' src/"
run_case "allow: grep -E (no alias trap)"          approve "grep -E 'foo|bar' file.txt"

echo
echo "## Empty / malformed input — must fail open"
run_case "allow: empty command"                    approve "" "/Users/jasonliggi"

echo
echo "==========================================="
echo "Results: PASS=$PASS  FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failures:"
  for f in "${FAILS[@]}"; do echo "  - $f"; done
  exit 1
fi
echo "All tests passed."
