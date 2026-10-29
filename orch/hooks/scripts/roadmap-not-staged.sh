#!/usr/bin/env bash
# PreToolUse on Bash: ROADMAP.md is a local queue and docs/reports/ is
# local review material; neither goes into git. Refuse a `git add` that
# names either or forces it past .gitignore.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
case "$cmd" in
  *"git add"*) ;;
  *) exit 0 ;;
esac
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]/])ROADMAP\.md([[:space:]]|$)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"orch: ROADMAP.md is a local work queue and is never committed. Leave it out of git add."}}'
  exit 0
fi
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]/])docs/reports(/|[[:space:]]|$)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"orch: docs/reports/ holds local step reports for review and is never committed. Leave it out of git add."}}'
fi
exit 0
