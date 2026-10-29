---
name: orch
description: The XO / ARCHITECT / FOREMAN orchestration. `/orch` explains the roles and how the session (XO) should work; `/orch init` sets a repo up; `/orch status` shows the queue; `/orch plan <request>` drafts the architect spawn prompt; `/orch build [steps]` drafts the foreman spawn prompt; `/orch run <request>` plans and builds with no approval stops. Use when asked to plan, execute a roadmap, run a request end to end unattended, or install orch.
---

# orch

Three roles. **XO** is this session: it classifies each request, drafts
a spawn prompt, shows it to the user, spawns a clean-context agent
(at once for ARCHITECT, after approval for FOREMAN), and reviews the
report. **ARCHITECT** (the
`architect` agent) plans into `ROADMAP.md`. **FOREMAN** (the `foreman`
agent) executes it. The roadmap is the only task source; `docs/LOG.md`
is the append-only record.

The argument decides what to do: `$ARGUMENTS`

## No argument: explain and orient

Read `${CLAUDE_PLUGIN_ROOT}/docs/ROLES.md` and summarise for the user,
in their project's terms, what XO does next for the kind of request in
front of it. Then stop.

## `init`

Set this repo up. Ask, with one question, for anything you can't read
from the repo:

- the project name (default: the directory name),
- a one-line description (read `README.md` first),
- the gate command (detect: `go.mod` means `go test ./...`,
  `Cargo.toml` means `cargo test`, `package.json` means `npm test`, a
  `justfile` with a `test` recipe means `just test`; otherwise ask).

Then write, without overwriting anything that exists unless told to:

1. `.orch.json` from `${CLAUDE_PLUGIN_ROOT}/templates/orch.json`.
2. `ROADMAP.md` from `templates/ROADMAP.md`. It is a local work queue,
   never committed.
3. `docs/LOG.md` from `templates/LOG.md`, with today's date in the T0
   entry, and an empty `docs/reports/` directory: FOREMAN writes one
   report per built step there (recap plus assumptions, shape in
   `templates/REPORT.md`). Local, like the roadmap.
4. `AGENTS.md` from `templates/AGENTS.md` with the placeholders filled
   (for Grok and any harness that doesn't see this plugin).
5. `CLAUDE.md`: append the lines in `templates/CLAUDE.md.snippet` if
   they're not already there. The first line imports `AGENTS.md`.
6. `.grok/agents/architect.md` and `foreman.md` from
   `templates/grok/agents/` (same bodies as this plugin's agents, for
   Grok).
7. `.gitignore`: add `tmp/`, `/ROADMAP.md` and `/docs/reports/` if
   missing.

Report what was written and what was left alone. Say that the hooks
(gate before commit, LOG append-only, session reminder) come from the
plugin and need no files in the repo. Don't commit.

## `status`

Print: the project and gate from `.orch.json`; the open steps in
`ROADMAP.md` (id, title, tag, one line each); the last three entries of
`docs/LOG.md`; any `docs/reports/*` step reports, with their assumption
counts, and any `tmp/agents/*` run logs newer than the last LOG entry.
Then stop.

## `plan <request>`

You are XO drafting an ARCHITECT spawn. Write the prompt below, show it
to the user with a two-line summary, and **spawn the `architect` agent
with it right away** (never `fork`). Do not wait for approval: planning
changes only `ROADMAP.md`, and the user approves the roadmap itself at
`build`. When the report comes back relay the roadmap and the open
questions. Send the user's answers to the same agent with SendMessage
so it keeps its context.

```
You are ARCHITECT for <project>. Clean context; nothing from this chat.

## User intent
<the request, constraints, non-goals, in the user's words where possible>

## Worker guidance
recon as defined; raise the tier only for a judgment-heavy compare.

## Read first
CLAUDE.md, AGENTS.md, ROADMAP.md, docs/LOG.md, <relevant paths>

## Constraints
Each step independently testable with a named gate (default: <gate>).
Open questions: max 5, each with a recommended default, words explained.
Run log: tmp/agents/architect-<UTC>.md.
Report headings: Roadmap written / Open questions / Assumptions / Run log.
```

Pick the model and effort for the spawn when the default (the agent's)
isn't right, and say why in the summary.

## `build [step ids]`

You are XO drafting a FOREMAN spawn for an accepted roadmap. Here you
do wait: draft, show, **wait for approval**, spawn clean. `ROADMAP.md`
is local and gitignored, so a FOREMAN in a worktree, a cloud session or
another machine may not have it: **paste each step's full body into the
prompt, verbatim**, not just its id. The prompt:

```
You are FOREMAN for <project>. Clean context; nothing from this chat.

## Queue
Steps <ids> from ROADMAP.md, accepted by the user on <date>. These are
the steps, verbatim; they are your sole task source. If ROADMAP.md
exists where you run, it must match them; if it doesn't exist, create
it from these (and from the orch plugin's templates/ROADMAP.md).

### <id> — <title> [todo]
**Touches:** …
**Must:** …
**Gate:** …
**Depends on:** …

<the next step, in full>

## Worker guidance
implementer as defined; <exceptions and why>.

## Process
Test-first, red then green, per step. Keep each
step's gate green (default: <gate>). Prune finished steps; append
docs/LOG.md. Per step, write docs/reports/<date>-<id>-<slug>.md from the
orch plugin's templates/REPORT.md: a recap for a person, then every
assumption (context, question, decision, alternatives, confidence),
including the implementers'. One commit per tranche; don't push.
Run log: tmp/agents/foreman-<UTC>.md.
Report headings: Completed / Evidence / Not completed / Gate / Commits / Reports / Run log.
```

When the report returns: read it, then `ROADMAP.md`, `docs/LOG.md`, the
new files under `docs/reports/` and `git log --stat`. Check that
Evidence really shows red then green and that the diff matches the
claimed steps. Relay the assumptions from the reports to the user, each
in a line, with the path of the report; a build with no assumptions
listed says so, and that is itself worth a second look. If steps
remain, spawn a fresh
FOREMAN for the remainder; if the roadmap is empty but the work isn't
done, a fresh ARCHITECT re-adds the steps. No new approval is needed
inside the accepted roadmap. **Two corrective rounds, then stop and
report to the user.**

## `run <request>`

Unattended: `plan` then `build`, with no approval stops. The user has
said up front that the roadmap ARCHITECT writes is accepted as written.
Use it only when the user asks for it by this verb or says in so many
words to run without review; never upgrade a `plan` or `build` into it.

1. Draft the ARCHITECT prompt exactly as in `plan`, with one extra line
   under **Constraints**:
   `No user is available: resolve each open question with its
   recommended default and record it under Assumptions.`
   Show it in one line and spawn at once.
2. When the report returns, read `ROADMAP.md`. If it is empty, or the
   report names something ARCHITECT could not decide, **stop and
   report**; that is the one case `run` hands back.
3. Otherwise draft the FOREMAN prompt exactly as in `build`, for every
   step in the roadmap, with "accepted by the user on <date>" replaced
   by "accepted unattended via `/orch run` on <date>". Spawn at once.
4. Review as in `build`: report, `ROADMAP.md`, `docs/LOG.md`,
   `git log --stat`, red then green. The correction loop and its
   **two-round cap** apply unchanged. Don't push.
5. Report once, at the end: the roadmap as planned, every default
   ARCHITECT took, every assumption from the step reports under
   `docs/reports/` with the report paths, Completed / Not completed,
   gate, commits, and the two run logs. Flag the defaults and the
   assumptions first; they are the decisions the user did not get to
   make.

## Bypass

Skip the subagent only when the request needs no code change and the
context is already in hand, or the user says to just do it. Then do it
in this session; plan mode is for that direct work, not a substitute
for ARCHITECT.
