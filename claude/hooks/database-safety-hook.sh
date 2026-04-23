#!/bin/bash
# Blocks destructive database commands before they execute.
# Registered as a PreToolUse hook for Bash in ~/.claude/settings.json

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

if echo "$command" | command grep -qiE 'supabase\s+db\s+reset'; then
  echo '{"decision":"block","reason":"supabase db reset is blocked — it drops the entire database. Use supabase migration up to apply migrations incrementally."}'
  exit 0
fi

echo '{"decision":"approve"}'
exit 0
