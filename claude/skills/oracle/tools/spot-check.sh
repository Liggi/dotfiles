#!/usr/bin/env bash
# Spot-check citations in a model-emitted review.
#
# Extracts two kinds of citations from a markdown file:
#   1. File paths with optional :line suffixes (e.g. `src/foo/bar.ts:123`)
#   2. Backtick-wrapped identifiers that look like function/type names
#
# For each citation, checks whether it exists in the target repo. Reports
# hits and misses. First-pass tool only — read the review manually and
# grep-verify anything load-bearing before quoting it back to the user.
#
# Usage:
#     ./spot-check.sh <review.md> <repo-root>
#
# Example:
#     ./spot-check.sh /tmp/gpt55pro-review.md ~/src/lattice-orchestrator

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <review.md> <repo-root>" >&2
    exit 2
fi

REVIEW="$1"
REPO="$2"

if [[ ! -f "$REVIEW" ]]; then
    echo "error: review file not found: $REVIEW" >&2
    exit 1
fi
if [[ ! -d "$REPO" ]]; then
    echo "error: repo root not a directory: $REPO" >&2
    exit 1
fi

echo "=== file paths ==="
# Match things that look like source paths: contain a `/`, end in a common
# source extension, optionally followed by `:line` or `:line-line`.
paths=$(grep -oE '[a-zA-Z0-9_./-]+\.(ts|tsx|js|jsx|py|go|rs|sql|md|json|yaml|yml|sh)(:[0-9]+(-[0-9]+)?)?' "$REVIEW" \
    | grep '/' \
    | sort -u)

hits=0
misses=0
miss_list=()
while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    # Strip :line suffix
    path="${p%%:*}"
    if [[ -f "$REPO/$path" ]]; then
        hits=$((hits + 1))
    else
        misses=$((misses + 1))
        miss_list+=("$p")
    fi
done <<< "$paths"

echo "hits:   $hits"
echo "misses: $misses"
if [[ ${#miss_list[@]} -gt 0 ]]; then
    echo
    echo "missing paths:"
    printf '  %s\n' "${miss_list[@]}"
fi

echo
echo "=== backtick-wrapped identifiers ==="
# Match `camelCase` / `PascalCase` / `snake_case` — identifiers only, not prose.
# Skip anything with spaces, slashes, or special chars that aren't identifier-like.
idents=$(grep -oE '`[a-zA-Z_][a-zA-Z0-9_]{2,}`' "$REVIEW" \
    | tr -d '`' \
    | sort -u)

# Common words to ignore (false positives — prose in backticks)
ignore='^(true|false|null|undefined|void|string|number|boolean|any|object|Array|Promise|Error|this|const|let|var|function|async|await|return|import|export|type|interface|class|extends|implements|default|static|public|private|protected|new|delete|typeof|instanceof)$'

checked=0
not_found=0
nf_list=()
while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    [[ "$id" =~ $ignore ]] && continue
    checked=$((checked + 1))
    if ! grep -rq --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.py' "$id" "$REPO" 2>/dev/null; then
        not_found=$((not_found + 1))
        nf_list+=("$id")
    fi
done <<< "$idents"

echo "checked:   $checked"
echo "not found: $not_found"
if [[ ${#nf_list[@]} -gt 0 ]]; then
    echo
    echo "missing identifiers (confirm manually — may be types in .d.ts, renames, or confabulation):"
    printf '  %s\n' "${nf_list[@]}"
fi

echo
echo "Done. This is a first-pass scan — manually verify load-bearing citations."
