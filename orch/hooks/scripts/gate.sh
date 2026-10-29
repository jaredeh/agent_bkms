#!/usr/bin/env bash
# PreToolUse on Bash: before a `git commit`, run the project's gate from
# .orch.json and refuse the commit if it fails. Skip with ORCH_SKIP_GATE=1
# in the environment or on the command line.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac
[ -f .orch.json ] || exit 0
gate=$(jq -r '.gate // ""' .orch.json)
[ -n "$gate" ] || exit 0
if [ "${ORCH_SKIP_GATE:-}" = "1" ] || printf '%s' "$cmd" | grep -q 'ORCH_SKIP_GATE=1'; then
  exit 0
fi
out=$(bash -c "$gate" 2>&1)
rc=$?
if [ "$rc" -ne 0 ]; then
  tail_out=$(printf '%s\n' "$out" | tail -n 25)
  reason="orch: the gate failed before the commit ($gate, exit $rc). Make it pass, or run the commit with ORCH_SKIP_GATE=1 and say why in the report.
$tail_out"
  jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
fi
exit 0
