#!/bin/bash
# Blocks command shapes that repeatedly hang or waste Jason's Claude sessions.
# Registered as a PreToolUse Bash hook in ~/.claude/settings.json.
#
# Blocks:
#   1. broad `find` over $HOME, ~/src, /, /Users/jasonliggi
#   2. unscoped `fd` from $HOME or ~/src; explicit `fd` over high-level roots
#   3. `ls -R` over high-level roots / git repo root with no narrow target
#   4. long foreground sleeps (>=30s) and while/until polling loops with sleep >=10s,
#      unless inside a tmux command or after ScheduleWakeup
#
# Override: append `# claude-allow-unsafe-command` to the command body, or set
# CLAUDE_ALLOW_UNSAFE_COMMAND=1.
#
# Fail-open: hook errors approve the command. This is a productivity hook, not a
# data-safety hook. Internal errors logged to /tmp/claude-command-safety-hook.log.

LOG="/tmp/claude-command-safety-hook.log"

input=$(cat)

approve() { echo '{"decision":"approve"}'; exit 0; }

block() {
  python3 - "$1" <<'PY' 2>>"$LOG" || approve
import json, sys
print(json.dumps({"decision": "block", "reason": sys.argv[1]}))
PY
  exit 0
}

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>>"$LOG")
cwd=$(printf '%s' "$input" | jq -r '.cwd // .workspace.current_dir // empty' 2>>"$LOG")
[ -z "$cwd" ] && cwd="$PWD"

[ -z "$command" ] && approve

# Override path
if printf '%s' "$command" | command grep -qE 'CLAUDE_ALLOW_UNSAFE_COMMAND=1|claude-allow-unsafe-command'; then
  echo "$(date '+%Y-%m-%dT%H:%M:%S') override cwd=$cwd command=$(printf '%s' "$command" | head -c 300)" >> "$LOG"
  approve
fi

# Rule 1: broad find over high-level roots
# Block: find / ...; find ~ ...; find $HOME ...; find /Users/jasonliggi ...; find ~/src ...
if printf '%s' "$command" | command grep -Eq '(^|[;&|][[:space:]]*)(/usr/bin/)?find[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(/|~|\$HOME|/Users/jasonliggi|~/src|\$HOME/src|/Users/jasonliggi/src)(/)?([[:space:]]|$)'; then
  block "Blocked broad find over a high-level directory (~, ~/src, /Users/jasonliggi, /). These hang for minutes traversing your home tree. Scope find to a specific repo/subdirectory, or use Glob/Grep tools, or retry with '# claude-allow-unsafe-command' and a reason if you really want this."
fi

# Rule 2a: explicit broad fd roots
if printf '%s' "$command" | command grep -Eq '(^|[;&|][[:space:]]*)fd\b.*[[:space:]](/|~|\$HOME|/Users/jasonliggi|~/src|\$HOME/src|/Users/jasonliggi/src)(/)?([[:space:]]|$)'; then
  block "Blocked fd over a high-level directory (~, ~/src, /Users/jasonliggi, /). Scope fd to a specific repo/subdir, or retry with '# claude-allow-unsafe-command'."
fi

# Rule 2b: unscoped fd from a high-level cwd (no path arg means fd defaults to cwd, which is broad)
if [ "$cwd" = "/Users/jasonliggi" ] || [ "$cwd" = "/Users/jasonliggi/src" ] || [ "$cwd" = "$HOME" ] || [ "$cwd" = "$HOME/src" ]; then
  if printf '%s' "$command" | command grep -Eq '(^|[;&|][[:space:]]*)fd([[:space:]]+-[^[:space:]]+)*([[:space:]]+[^/[:space:];&|][^[:space:];&|]*)?[[:space:]]*([;&|]|$)'; then
    block "Blocked unscoped fd from $cwd. fd with no path argument searches the current directory, which is too broad here. cd into a specific repo first, or pass an explicit narrow path."
  fi
fi

# Rule 3: broad ls -R
# Block if: (A) ls -R with no target (followed only by pipe/end/redirect), OR
#          (B) ls -R with explicit broad target (. ~ $HOME / /Users/jasonliggi[/src]).
# Allow:   ls -R src/app/api  (narrow target, even when piped further)
if printf '%s' "$command" | command grep -Eq '(^|[;&|][[:space:]]*)(command[[:space:]]+)?(/bin/)?ls\b[^\n;&|]*[[:space:]]-[a-zA-Z]*R'; then
  # Check A: ls -R with no target token before pipe/end
  if printf '%s' "$command" | command grep -Eq 'ls\b[^\n;&|]*-[a-zA-Z]*R[[:space:]]*([;&|]|$)'; then
    block "Blocked broad ls -R with no target. Use a specific subdirectory and pipe to head, or retry with '# claude-allow-unsafe-command'."
  fi
  # Check B: ls -R with explicit broad target
  if printf '%s' "$command" | command grep -Eq 'ls\b[^\n;&|]*-[a-zA-Z]*R[[:space:]]+(\.|~|\$HOME|/Users/jasonliggi(/src)?|/)([[:space:]/]|$|[;&|])'; then
    block "Blocked broad ls -R (target is . / ~ / a high-level root). Use a specific subdirectory and pipe to head, or retry with '# claude-allow-unsafe-command'."
  fi
fi

# Rule 4: long foreground sleeps and polling loops, unless tmux-wrapped or paired with ScheduleWakeup/run_in_background
if ! printf '%s' "$command" | command grep -Eq 'tmux[[:space:]]+(new-session|send-keys|run-shell)|ScheduleWakeup|run_in_background'; then
  # Long single sleep: sleep 30, sleep 60s, sleep 300, etc.
  if printf '%s' "$command" | command grep -Eq '(^|[;&|][[:space:]]*)sleep[[:space:]]+([3-9][0-9]|[1-9][0-9]{2,})s?\b'; then
    block "Blocked long foreground sleep (>=30s). This eats your turn — Claude can't respond and you can't intervene. Use tmux + a later check, or ScheduleWakeup, or run_in_background. Override with '# claude-allow-unsafe-command' if intentional."
  fi
  # Polling loop: while/until ... sleep N where N >= 10
  # Use tr to collapse newlines so the regex sees the loop on one line
  flat=$(printf '%s' "$command" | tr '\n' ' ')
  if printf '%s' "$flat" | command grep -Eq '(while|until)\b.*\bsleep[[:space:]]+([1-9][0-9]|[1-9][0-9]{2,})s?\b'; then
    block "Blocked foreground polling loop with long sleep (>=10s). Use tmux, the Monitor tool with an until-loop, or ScheduleWakeup. These don't hold your turn open."
  fi
fi

approve
