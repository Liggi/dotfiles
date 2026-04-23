#!/bin/bash
# PreToolUse hook that blocks any `git commit` Bash command containing
# Claude Code attribution lines. Turns the "NEVER add attribution" rule
# from ~80% advisory to 100% deterministic.
#
# To activate:
#   1. mv ~/claudefiles/skill-drafts/commit-attribution-hook.sh \
#         ~/.claude/hooks/commit-attribution-hook.sh
#   2. chmod +x ~/.claude/hooks/commit-attribution-hook.sh
#   3. Add to ~/.claude/settings.json under hooks.PreToolUse,
#      alongside the existing database-safety-hook.sh entry:
#
#      {
#        "matcher": "Bash",
#        "hooks": [
#          {
#            "type": "command",
#            "command": "/Users/jasonliggi/.claude/hooks/commit-attribution-hook.sh"
#          }
#        ]
#      }
#
#   (You can combine this into the same "Bash" matcher array as
#   database-safety-hook.sh — hooks in the array run in order and any
#   "block" decision short-circuits.)

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only inspect git commit commands
if ! echo "$command" | command grep -qE '\bgit\s+commit\b'; then
  echo '{"decision":"approve"}'
  exit 0
fi

# Block if the command body contains any known Claude attribution pattern
if echo "$command" | command grep -qiE '(Generated with \[?Claude Code|Co-Authored-By:\s*Claude|🤖\s*Generated with)'; then
  echo '{"decision":"block","reason":"Commit message contains Claude Code attribution (\"Generated with [Claude Code]\" or \"Co-Authored-By: Claude\"). Strip those lines and retry with a clean [category] brief description message."}'
  exit 0
fi

echo '{"decision":"approve"}'
exit 0
