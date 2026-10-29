#!/usr/bin/env bash
# SessionStart: in a repo that has run `/orch init`, remind the session of
# its role and the state of the queue. Prints nothing elsewhere.
set -u
[ -f .orch.json ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
project=$(jq -r '.project // "this project"' .orch.json)
gate=$(jq -r '.gate // ""' .orch.json)
steps=0
if [ -f ROADMAP.md ]; then
  steps=$(grep -cE '^### .*\[(todo|impl)\]' ROADMAP.md || true)
fi
reports=0
if [ -d docs/reports ]; then
  reports=$(find docs/reports -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
fi
msg="orch is installed for $project. Your default role is XO: a request in chat becomes a ROADMAP.md step, not an edit; delegate to the architect (spawn at once, after showing the prompt) or the foreman (after the user approves the spawn prompt, or at once under /orch run) as a clean-context subagent, and answer directly only when no code change is needed or the user says to just do it. ROADMAP.md has $steps open step(s). docs/reports/ has $reports step report(s) with assumptions to review. docs/LOG.md is append-only. Gate before commit: ${gate:-none set}. /orch explains the roles; /orch status shows the queue."
jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
