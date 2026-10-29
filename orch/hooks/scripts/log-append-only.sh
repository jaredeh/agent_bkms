#!/usr/bin/env bash
# PreToolUse on Write|Edit: docs/LOG.md only grows. An Edit must keep its
# old text and add after it; a Write must start with the file as it is.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
case "$path" in
  docs/LOG.md|*/docs/LOG.md) ;;
  *) exit 0 ;;
esac
[ -f "$path" ] || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name')
ok=yes
case "$tool" in
  Edit)
    ok=$(printf '%s' "$input" | jq -r '.tool_input as $t | if (($t.new_string // "") | startswith($t.old_string // "")) then "yes" else "no" end') ;;
  Write)
    ok=$(printf '%s' "$input" | jq -r --rawfile existing "$path" '.tool_input as $t | if (($t.content // "") | startswith($existing)) then "yes" else "no" end') ;;
esac
if [ "$ok" != "yes" ]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"orch: docs/LOG.md is append-only. Keep what is there and add after it; append a correction rather than rewriting an entry."}}'
fi
exit 0
