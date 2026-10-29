# Roles: XO, ARCHITECT, FOREMAN

Three roles. XO is the top-level session. ARCHITECT and FOREMAN are the
`architect` and `foreman` agents this plugin defines, spawned with a
clean context: a fresh agent *is* the reset between planning and
building. Only its report comes back.

| Concern | Mechanism |
|---|---|
| Context bloat | Clean-context agents; only the report returns to XO |
| Scope creep | FOREMAN builds only what `ROADMAP.md` says |
| User control | XO shows the spawn prompt and waits for approval |
| Durable history | `docs/LOG.md`, append-only, enforced by a hook |
| Forensic debug | `tmp/agents/<role>-<stamp>.md`, read only on a mismatch |
| Planning continuity | XO messages the same ARCHITECT with answers; its context is kept |
| Mechanical rules | Hooks: gate before commit, LOG append-only, session reminder |

## XO

The executive officer. Stays thin, delegates, reviews. Never absorbs a
subagent's working context.

1. Classify the request: plan it (ARCHITECT), build it (FOREMAN), or
   handle it directly (bypass, below).
2. Pick the model and effort for the spawn when the agent's defaults
   aren't right, and say why.
3. Draft the spawn prompt (`/orch plan`, `/orch build` give the shape).
4. Show it with a short summary and **wait for approval**.
5. Spawn clean: the Agent tool with the agent's name, never `fork`.
6. Review: the report, `ROADMAP.md`, `docs/LOG.md`, `git log --stat`.
   Check Evidence shows red then green and the diff matches the claims.
7. Relay what matters. Open the run log only when the report and the
   repo disagree, a gate failed, or a corrective round is running.

**Bypass**: no code change needed and the context is in hand, or the
user says to just do it. Plan mode is for XO's own direct work, not a
substitute for ARCHITECT.

**Correction loop**: steps left in the roadmap, a fresh FOREMAN for the
remainder; roadmap empty but work not done, a fresh ARCHITECT re-adds
steps, then a fresh FOREMAN. No new approval inside the accepted
roadmap; one line of notice per round. **Two rounds, then a human.**

**Continuity**: to continue a spawned agent (answers to its questions, a
follow-up), message it with SendMessage rather than spawning again.

## ARCHITECT

Plans with the user until the plan is accepted. Writes only
`ROADMAP.md` and its run log. Spawns `recon` for deep dives, never to
implement. Has no channel to the user: open questions, at most five,
each with a recommended default and the words explained, go through XO.
Smaller calls under Assumptions. Full contract: `agents/architect.md`.

## FOREMAN

Builds an accepted roadmap. Sole task source: `ROADMAP.md`. Spawns
`implementer` per step and reviews the result. Test-first, red then
green, gate green. Prunes finished steps; appends `docs/LOG.md`. Reports
with Evidence. Full contract: `agents/foreman.md`.

## Models

Pinned in each agent's frontmatter, so XO doesn't have to pass them as
prose: `architect` and `foreman` on Opus, `implementer` and `recon` on
Sonnet. Override per spawn (the Agent tool's `model` and `effort`) when
a task warrants it, and say why. Revise the pins as models change.

## Memory and the log

The harness keeps a memory directory for the agent's own notes about
the person and the project. That is not the project record.
`docs/LOG.md` is: what shipped, when, in which commits, readable by
anyone who clones the repo.

## The queue is local

`ROADMAP.md` is gitignored: a live work queue, not part of the
project's history. `/orch init` writes one in a fresh clone; the
durable record is `docs/LOG.md` and git. Because it doesn't travel, a
FOREMAN spawn carries the accepted steps' full bodies in its prompt,
so it can run in a worktree or a cloud session that has no roadmap.
