# ORCH.md — Portable XO / ARCHITECT / FOREMAN orchestration

**Self-contained.** This document alone is enough to install the full
orchestration system in any software repo. Do **not** assume access to any
other repository, path, or prior chat. Create every file from the templates
in this document.

**What you build:** three agent roles (XO, ARCHITECT, FOREMAN), a local work
queue (`ROADMAP.md`), an append-only history (`docs/LOG.md`), process docs,
harness agent definitions, and gitignore rules.

**Placeholders** (replace when installing):

| Token | Meaning |
|-------|---------|
| `<PROJECT>` | Short project name |
| `<ONE_LINE>` | One-line project description |
| `<GATE_CMD>` | Real package test command for this repo (e.g. `cargo test`, `go test ./...`, `npm test`, `make test`) |
| `<YYYY-MM-DD>` | Install date |

---

## 1. Mental model

```text
User chat
    │
    ▼
┌───────────────────────────────────────────────────────────┐
│  XO  (default role of the top-level session)              │
│  — stays thin; never absorbs subagent working context     │
│  — classifies: plan | execute | answer directly           │
│  — drafts spawn prompt, surfaces it, WAITS for approval   │
│  — spawns clean-context ARCHITECT or FOREMAN              │
│  — reviews fixed-heading report + ROADMAP + LOG + git     │
└───────────────────────────┬───────────────────────────────┘
                            │
          ┌─────────────────┴─────────────────┐
          ▼                                   ▼
   ARCHITECT (plan)                    FOREMAN (execute)
   — only writes ROADMAP.md            — sole task source: ROADMAP.md
     (+ run log under tmp/agents/)     — implements via workers
   — does NOT implement product code   — test-first red → green
   — spawns deep-dive/recon workers    — prune finished steps from ROADMAP
   — open questions → XO → user        — append docs/LOG.md
   — assumptions for small decisions
          │                                   │
          └──────── report (fixed headings) ──┘
                            │
                            ▼
                     XO reviews / corrects
```

| Concern | Mechanism |
|---------|-----------|
| Context bloat | Clean-context subagents; only the **report** returns to XO |
| Scope creep | FOREMAN may **not** invent work from chat; only `ROADMAP.md` |
| User control | XO surfaces spawn prompts and **waits for approval** before spawn |
| Durable history | `docs/LOG.md` append-only; git for code; ROADMAP is ephemeral queue |
| Forensic debug | `tmp/agents/<role>-<stamp>.md` (gitignored); XO opens only when needed |
| Planning continuity | ARCHITECT has no user channel; XO relays Q&A to the **same** agent |
| Deep planning context | ARCHITECT spawns recon workers; only conclusions enter ROADMAP |

---

## 2. File inventory

### 2.1 Tracked (commit these)

| Path | Role |
|------|------|
| `ORCH.md` | This blueprint (optional but recommended) |
| `AGENTS.md` | Thin root: hard rules, role bullets, where-to-look |
| `docs/ROLES.md` | Full XO / ARCHITECT / FOREMAN contracts |
| `docs/DEVELOPMENT.md` | Delivery discipline: steps, gates, red→green, status tags |
| `docs/LOG.md` | Append-only completed work |
| `docs/ROADMAP.md.template` | Bootstrap source for local `ROADMAP.md` |
| `docs/README.md` | Docs index |
| `.claude/agents/architect.md` | Claude ARCHITECT definition |
| `.claude/agents/foreman.md` | Claude FOREMAN definition |
| `.grok/agents/architect.md` | Grok ARCHITECT definition |
| `.grok/agents/foreman.md` | Grok FOREMAN definition |

### 2.2 Local / gitignored (do **not** commit)

| Path | Role |
|------|------|
| `/ROADMAP.md` (repo root only) | Live work queue |
| `tmp/` (includes `tmp/agents/`) | Run logs and scratch |
| Secrets (`.env`, credential dumps, …) | Never commit |

### 2.3 Minimum `.gitignore` additions

```gitignore
tmp/
.env

# Local work queue (bootstrap: cp docs/ROADMAP.md.template ROADMAP.md)
/ROADMAP.md
```

Do **not** gitignore `.claude/agents/` or `.grok/agents/`. Machine-local harness
settings (e.g. `.claude/settings.local.json`) may stay ignored.

---

## 3. Bootstrap sequence

### Step A — Directories

```bash
mkdir -p docs .claude/agents .grok/agents tmp/agents
```

### Step B — Gitignore

Append §2.3 to `.gitignore` (create the file if missing).

### Step C — Write every tracked file

Copy each full template from §5–§11 into the path named in the section heading.
Replace all placeholders (`<PROJECT>`, `<GATE_CMD>`, …).

**Do not shorten** role contracts, report headings, question caps, or
prune/append rules. Only project-specific hard rules and gate commands change.

### Step D — Bootstrap the local queue

```bash
cp docs/ROADMAP.md.template ROADMAP.md
```

### Step E — First LOG entry

Append the T0 entry from §9 (with real date).

### Step F — Wire the harness

- **Claude Code:** agents under `.claude/agents/` (YAML frontmatter with
  `name`, `description`, optional `tools`).
- **Grok / similar:** agents under `.grok/agents/` (`name`, `description`).
  Paths in agent bodies are relative to the agent file (`../../AGENTS.md`).
- **Top-level session:** project/system instructions must load `AGENTS.md`
  and state that the **default role is XO**.

If the target harness uses a different agents directory, still write the same
agent bodies; only the directory name changes.

### Step G — Smoke check (process, not product)

1. As XO, draft an ARCHITECT spawn for a trivial doc-only plan; surface prompt;
   user approves; ARCHITECT writes steps into `ROADMAP.md` with named gates.
2. User accepts ROADMAP; XO spawns FOREMAN; FOREMAN implements, prunes ROADMAP,
   appends LOG, reports with `## Evidence`.
3. Confirm root `ROADMAP.md` is untracked; `docs/LOG.md` and the template are
   tracked.

---

## 4. Runtime protocol (normative)

### 4.1 XO (default session role)

**Duties (delegated work):**

1. Classify: **plan** (ARCHITECT), **execute** (FOREMAN), or **direct** (bypass).
2. Pick models for that role **and** for workers it will spawn (ARCHITECT
   deep-dive/recon and/or FOREMAN implementers).
3. Draft the spawn prompt (model pick + reasoning; **worker-model guidance as
   text** for nested workers — XO cannot configure them via harness alone).
4. Surface the prompt + short human summary; **wait for user approval**.
5. Spawn **clean context** (never fork parent session context).
6. Review report + `ROADMAP.md` + `docs/LOG.md` + `git log --stat`.
7. Relay what matters; open `tmp/agents/*` only on mismatch, gate fail, or
   corrective rounds.

**Bypass (no subagent)** only when:

- No code change needed and context is already in hand, **or**
- User explicitly says to just do it.

**Correction loop** (no re-approval while inside already-approved ROADMAP):

| Situation | Action |
|-----------|--------|
| Steps left in `ROADMAP.md` | Fresh FOREMAN for remainder |
| ROADMAP empty but work not done | Fresh ARCHITECT re-adds steps → FOREMAN |
| Cap | **Two** corrective rounds, then stop and report to user |

One-line notice each corrective round.

**Context hygiene:** never inherit parent context for ARCHITECT/FOREMAN. Resume
an existing subagent for continued planning Q&A rather than re-spawning.

### 4.2 ARCHITECT

- **May edit only:** `ROADMAP.md`, template bootstrap, `tmp/agents/architect-*.md`.
- **Must not** implement product code (that is FOREMAN).
- **Spawn deep-dive subagents when needed** (recon, inventory, blast-radius,
  option compare). Prefer explore/read-only; workers must not implement.
- Follow worker-model guidance from the XO spawn prompt.
- Each ROADMAP step: independently testable; names its **gate**.
- Report headings (only these reach XO):

```text
## Roadmap written
## Open questions
## Assumptions
## Run log
```

- Open questions: **max 5**, each with **recommended default**.
- Smaller decisions → `## Assumptions`.
- Run log: `tmp/agents/architect-<UTC stamp>.md` (include worker findings).

### 4.3 FOREMAN

- **Sole task source:** root `ROADMAP.md` (re-read; no inventing from chat).
- Prefer implementation workers; review them.
- Test-first: write test → **confirm red** → implement → **confirm green**.
- On step/tranche complete: **remove** finished work from `ROADMAP.md`;
  **append** short entry to `docs/LOG.md`.
- Prefer one commit/PR per named tranche when ROADMAP asks for stacks.
- Report headings:

```text
## Completed
## Evidence
## Not completed
## Gate
## Commits
## Run log
```

- **`## Evidence` is mandatory** (test name, red output, green output, or
  explicit N/A with reason).
- Run log: `tmp/agents/foreman-<UTC stamp>.md`.

### 4.4 Live ROADMAP shape

1. Role preamble (from template — keep it).
2. **`## Context`** — locked decisions, slice, links.
3. **`## Remaining work`** — ordered steps with ids, touches, gates, status.
4. **`## Out of scope`**
5. **`## Deferred`**

| Tag | Meaning |
|-----|---------|
| `[todo]` | Not started |
| `[impl]` | Code present; always-on gate test still pending |
| `[done]` | Shipped with gate green (usually pruned immediately) |

Prune completed steps when a tranche ships. Detail lives in git + LOG + tests.

### 4.5 LOG shape

- Append-only; newest at the **bottom**.
- Do not rewrite historical entries; append corrections.

```markdown
## YYYY-MM-DD — <task id or title>

- Summary of what shipped
- Optional: commit SHA(s) or PR link
```

### 4.6 Model defaults (not pinned in agent files)

| Role | Capability |
|------|------------|
| ARCHITECT | Strong reasoning |
| FOREMAN | Strong reasoning |
| Leaf implementers (FOREMAN workers) | Mid-tier |
| Explore/recon (ARCHITECT workers) | Mid-tier or cheap/fast |
| Mechanical/rote | Cheap/fast |

---

## 5. File: `AGENTS.md`

```markdown
# Project rules for <PROJECT>

**<PROJECT>** — <ONE_LINE>.

- Describe major directories briefly.
- Name supported day-to-day tooling entrypoints for this repo.

## Roles

- **XO** (default) orchestrates: picks the role and the models, surfaces the
  spawn prompt for approval, spawns ARCHITECT or FOREMAN as a clean-context
  subagent, reviews the result.
- **ARCHITECT** plans work into local `ROADMAP.md` with the user until accepted;
  spawns deep-dive/recon subagents as needed (does not implement product code).
- **FOREMAN** executes an accepted ROADMAP (subagents), prunes finished steps,
  appends [`docs/LOG.md`](docs/LOG.md).

Details: [`docs/ROLES.md`](docs/ROLES.md), process: [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

Bootstrap work queue: `cp docs/ROADMAP.md.template ROADMAP.md` (root `ROADMAP.md`
is gitignored).

## Hard rules

1. **Default role is XO** — a request in chat becomes a `ROADMAP.md` entry, not
   an edit. Delegate: surface the spawn prompt and wait for approval before
   running any subagent. Answer directly only when no code change is needed and
   the context is already in hand, or when the user says to just do it.
   Implement only from an accepted ROADMAP step (as FOREMAN).
2. **Secrets** — never commit `.env`, real credentials, or secret dumps.
3. **Project rules** — add domain-specific hard rules here (API contracts,
   style, deploy, etc.).
4. **Test gates** — keep the gate green for packages you touch before commits.
   Typical gate: `<GATE_CMD>` (or the command each ROADMAP step names).
5. **FOREMAN task source** — execute from local `ROADMAP.md` only; do not invent
   scope from chat history alone.

## Where to look

| Need | Doc |
|------|-----|
| Docs index | [`docs/README.md`](docs/README.md) |
| Process / gates | [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) |
| Roles | [`docs/ROLES.md`](docs/ROLES.md) |
| Subagent definitions (Claude) | [`.claude/agents/`](.claude/agents) |
| Subagent definitions (Grok) | [`.grok/agents/`](.grok/agents) |
| Completed work | [`docs/LOG.md`](docs/LOG.md) |
| ROADMAP bootstrap | [`docs/ROADMAP.md.template`](docs/ROADMAP.md.template) |
| Orchestration blueprint | [`ORCH.md`](ORCH.md) |
```

---

## 6. File: `docs/ROLES.md`

Write this file **as-is** (only replace `<GATE_CMD>` if you want a default
example in the FOREMAN gate line).

```markdown
# Roles: XO, ARCHITECT, FOREMAN

Agents working on this project use three roles. All load [`AGENTS.md`](../AGENTS.md)
and follow [`DEVELOPMENT.md`](DEVELOPMENT.md).

**XO** is the default role of the top-level session. ARCHITECT and FOREMAN run
as clean-context subagents defined in [`.claude/agents/`](../.claude/agents)
and [`.grok/agents/`](../.grok/agents) — a fresh subagent *is* the context
reset between planning and execution.

## XO

The executive officer. Stays thin, delegates, reviews. Never absorbs a
subagent's working context.

### Duties

1. Classify the request: plan it (ARCHITECT), execute it (FOREMAN), or handle it
   directly (see Bypass).
2. Pick the model for that role **and** for the workers it will spawn.
3. Draft the spawn prompt.
4. Surface the prompt to the user with a short human-readable summary, and
   **wait for approval**.
5. Spawn, review the report, relay what matters.

### Bypass — skip the subagent when

- The request needs no code change and the required context is already in hand.
  Spawning to answer a question already answered wastes the user's money.
- The user explicitly says to just do it.

### Model guidance

Deliberately **not** pinned in the agent files. Model capability moves fast, and
choosing well — then telling the subagent *why* — is a core part of this role.
Pass the choice via the harness model parameter and state the pick and
reasoning in the surfaced prompt.

ARCHITECT and FOREMAN both spawn their own workers (deep-dive recon vs
implementation), which XO cannot reach directly, so **worker-model guidance
goes into the ARCHITECT and FOREMAN spawn prompts** as text.

Current default, expected to be revised as models change: ARCHITECT strong
reasoning model, FOREMAN strong reasoning model, leaf implementation workers
mid-tier, explore/recon workers mid-tier or cheap/fast, mechanical/rote
workers cheap/fast.

### Two-tier reporting

- **The report** crosses into XO's context: fixed headings, with evidence —
  `path:line` refs, test names, red → green output. Target ~200 lines, no hard
  cap. A truncated report costs more than it saves when the reviewer has to
  re-derive what happened.
- **The run log** at `tmp/agents/<role>-<stamp>.md` (gitignored) holds the
  forensic detail: full command output, dead ends, worker prompts. The report's
  last line points at it.

### Review contract

Read the report plus `ROADMAP.md`, [`LOG.md`](LOG.md), and `git log --stat`.
Check that `## Evidence` really shows red → green and that claimed steps match
the diff.

Stay out of the weeds. Open the run log **only** when the report and the repo
disagree, a gate failed, or a corrective round is already running. XO is
first-line debug for the *process* — the material is there when needed and
unread when not.

### Correction loop

- Steps left unfinished in `ROADMAP.md` → spawn a fresh FOREMAN for the
  remainder.
- `ROADMAP.md` cleared but the work was not actually done → a fresh ARCHITECT
  re-adds the missing or botched steps, then a fresh FOREMAN executes them.
- No new user approval is needed while the work stays inside the
  already-approved ROADMAP. Give a one-line notice each round.
- **Cap: two corrective rounds**, then stop and report to the user. Guards
  against looping on a stuck FOREMAN.

### Context hygiene

- Never fork/inherit the parent session context for these roles — a fork
  inherits the parent's context, which defeats the reset. Spawn clean.
- Require the report headings and the run-log path.
- To continue an existing subagent, resume/message it rather than re-spawning
  and re-paying for context.

## ARCHITECT

Plans work with the user until the plan is **accepted**.

- Writes and refines the local work queue: root [`ROADMAP.md`](../ROADMAP.md)
  (bootstrap from [`ROADMAP.md.template`](ROADMAP.md.template) if missing).
- Captures decisions, scope, ordering, and out-of-scope notes in that file.
- Does **not** implement the plan (unless the user explicitly asks). Product
  code changes belong to FOREMAN.
- **Spawns subagents for deep dives** when planning needs more context than a
  light read: codebase recon, inventory, compare options, blast-radius, or
  “what would break if…”. Prefer explore/read-only workers; review their
  findings; fold conclusions into `ROADMAP.md` and the run log. Do **not**
  use workers to implement the plan.
- Hand-off: plan status is accepted; FOREMAN may execute.

**Question relay.** As a subagent, ARCHITECT has no channel to the user. It puts
decisions it needs under `## Open questions` (max 5, each with a recommended
default); XO asks the user and returns the answers to the *same* agent, so
ARCHITECT keeps its context across planning rounds.

**Worker models** come from the XO spawn prompt (same pattern as FOREMAN).

Definitions: [`.claude/agents/architect.md`](../.claude/agents/architect.md),
[`.grok/agents/architect.md`](../.grok/agents/architect.md).

## FOREMAN

Executes an **accepted** ROADMAP.

1. Re-read root `ROADMAP.md` as the sole task source (do not invent scope).
2. Execute steps (prefer subagents for implementation; review their results).
3. Keep the agreed gate green — the package test command named by each step
   for the packages it touches (example form: `<GATE_CMD>`).
4. On completion of a step or tranche:
   - **Remove** finished work from `ROADMAP.md`.
   - **Append** a short summary to [`LOG.md`](LOG.md) (date, task id/title,
     summary, optional commit/PR refs).
5. Prefer one stacked commit (or PR) per named tranche when the ROADMAP asks
   for stacked landings.

Reports with `## Evidence` — test name, red output, green output, per step.
Worker model comes from the spawn prompt.

Definitions: [`.claude/agents/foreman.md`](../.claude/agents/foreman.md),
[`.grok/agents/foreman.md`](../.grok/agents/foreman.md).

## Bootstrap

```bash
cp docs/ROADMAP.md.template ROADMAP.md
```

Root `ROADMAP.md` is gitignored. The template and `LOG.md` are committed.

## Hard boundaries

- Durable product and process docs live under `docs/`; root `AGENTS.md` is
  hard rules + pointers only.
- FOREMAN does **not** invent scope from chat history. `ROADMAP.md` is the
  sole task source.
```

---

## 7. File: `docs/DEVELOPMENT.md`

```markdown
# Development process

How we ship work: ordered, **independently testable** steps. The open task list
is the local [`ROADMAP.md`](../ROADMAP.md) (bootstrap from
[`ROADMAP.md.template`](ROADMAP.md.template)); this file is the **discipline**
for every step. Agent roles: [`ROLES.md`](ROLES.md). Completed work:
[`LOG.md`](LOG.md).

## Delivery rules

- Work is broken into **ordered, independently testable steps** (often grouped
  into named tranches).
- Each step updates tests, docs, and anything else the change touches.
- After a step, the **named gate for packages it touches must stay green**.
- When changing public APIs or shared contracts, update the contract source
  first, then regenerate consumers, then land handlers/clients/tests together
  (if this project has formal contracts).

## Gates

There is typically **no monorepo-wide mega-test**. Each ROADMAP step must name
the gate for the packages it touches. Prefer the package's everyday test
command, for example:

```bash
<GATE_CMD>
```

Document additional integration or e2e commands here if the project has them.

## Roles (XO → ARCHITECT → FOREMAN)

See [`ROLES.md`](ROLES.md) for the full contract. Short form:

1. **XO** (default role of the session) picks the role and models, surfaces the
   spawn prompt for approval, and delegates.
2. **ARCHITECT** plans into local `ROADMAP.md` until accepted — questions relay
   back through XO; may spawn deep-dive/recon subagents (does not implement
   product code).
3. **FOREMAN** executes (subagents), keeps the gate green, **removes** finished
   steps from `ROADMAP.md`, and **appends** to [`LOG.md`](LOG.md).
4. **XO** reviews and re-spawns to close gaps, within the approved ROADMAP.

The context reset between planning and execution is a fresh subagent from
[`.claude/agents/`](../.claude/agents) or [`.grok/agents/`](../.grok/agents);
only its report crosses back.

Bootstrap: `cp docs/ROADMAP.md.template ROADMAP.md`. Root `ROADMAP.md` is
gitignored; the template and log are committed.

## Test-first: red → green

Every feature or fix follows the same discipline:

1. **Write the test first** asserting the *desired* post-fix behavior.
2. **Confirm it fails** against the current code (red). Keep the default gate
   green for unrelated packages in between (isolate with packages, build tags,
   or skip markers if needed until the step lands).
3. **Implement the fix/feature** until the test passes (green); fold the test
   into the package's always-on suite.
4. **No step is "done"** without its test in the always-on suite for that
   package.

### Status legend (roadmap steps)

| Tag | Meaning |
|-----|---------|
| **[done]** | Shipped with its test green in the package's default gate |
| **[impl]** | Code shipped and building/linting, but a dedicated always-on green test is still pending (not "done" by the rule above) |
| **[todo]** | Not started |

When a tranche ships, **prune completed steps from `ROADMAP.md`**. Detail lives
in git history, [`LOG.md`](LOG.md), and the tests that pin the behavior.

## Where tests live

| Layer | Where | Role |
|-------|--------|------|
| Package gate | Next to the package (`<GATE_CMD>` or equivalent) | Everyday check for the package under change |
| Integration | Package or repo `tests/` | Heavier stacks (docker, multi-service) |
| Contracts | Specs / schema dirs if any | Shared API source of truth |

Prefer the layer that matches the behavior.

## Related

Agent hard rules + pointers: [`AGENTS.md`](../AGENTS.md). Roles:
[`ROLES.md`](ROLES.md). Orchestration blueprint: [`ORCH.md`](../ORCH.md).
```

---

## 8. File: `docs/ROADMAP.md.template`

```markdown
# ROADMAP

**How we work** — test-first, red → green, gates, status tags — is documented in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md). Follow that process for every step
below.

**Roles** (see [`docs/ROLES.md`](docs/ROLES.md)):

- **XO** — default session role; spawns the roles below as clean-context
  subagents and reviews their reports.
- **ARCHITECT** — plans tasks here until the plan is accepted; may spawn
  deep-dive/recon subagents; open questions relay through XO.
- **FOREMAN** — executes tasks by spawning subagents, reviews completion, removes
  finished work from this file, and appends a summary to [`docs/LOG.md`](docs/LOG.md).

Bootstrap (fresh clone):

```bash
cp docs/ROADMAP.md.template ROADMAP.md
```

Root `ROADMAP.md` is **gitignored** — it is a local work queue only. This template
is tracked. Completed work is recorded in [`docs/LOG.md`](docs/LOG.md).

---

## Remaining work

_(ARCHITECT fills this in with the user. FOREMAN executes from this file only.)_
```

ARCHITECT extends the live `ROADMAP.md` with Context / Out of scope / Deferred
as needed; the template is the minimum bootstrap.

---

## 9. File: `docs/LOG.md`

```markdown
# Work log

Append-only history of completed ROADMAP work. FOREMAN appends a short entry
after each landed step or tranche. Newest entries at the **bottom**.

Format per entry:

```
## YYYY-MM-DD — <task id or title>

- Summary of what shipped
- Optional: commit SHA(s) or PR link
```

---

<!-- Entries below this line -->

## <YYYY-MM-DD> — T0 Scaffold XO / ARCHITECT / FOREMAN workflow

- Created `docs/LOG.md`, `docs/ROADMAP.md.template`, `docs/ROLES.md`,
  `docs/DEVELOPMENT.md`, `docs/README.md`.
- Added thin root `AGENTS.md` (XO default role; hard rules + pointers).
- Agent defs: `.claude/agents/{architect,foreman}.md` and
  `.grok/agents/{architect,foreman}.md`.
- Gitignored root `ROADMAP.md`; bootstrap `cp docs/ROADMAP.md.template ROADMAP.md`.
- Documented XO → ARCHITECT → FOREMAN flow; package gates as in DEVELOPMENT.md.
- Installed from portable `ORCH.md`.
```

---

## 10. File: `docs/README.md`

```markdown
# Documentation

Process and agent-workflow docs for **<PROJECT>**.

Root keeps: [`README.md`](../README.md) (if any) and [`AGENTS.md`](../AGENTS.md).
Local-only (gitignored): `ROADMAP.md` (bootstrap from the template below).

| Doc | Purpose |
|-----|---------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | How we ship: test-first, gates, step status |
| [ROLES.md](ROLES.md) | XO / ARCHITECT / FOREMAN; plan → execute → LOG |
| [LOG.md](LOG.md) | Append-only history of completed ROADMAP work |
| [ROADMAP.md.template](ROADMAP.md.template) | Bootstrap for local `ROADMAP.md` work queue |

## Related (repo root)

| Path | Role |
|------|------|
| [`AGENTS.md`](../AGENTS.md) | Hard rules + pointers for agents |
| [`ORCH.md`](../ORCH.md) | Portable orchestration blueprint |
| [`.claude/agents/`](../.claude/agents) | Claude ARCHITECT / FOREMAN defs |
| [`.grok/agents/`](../.grok/agents) | Grok ARCHITECT / FOREMAN defs |
```

---

## 11. Agent definition files

Write **identical job bodies** for Claude and Grok. Only frontmatter differs.
Replace `<PROJECT>` and `<GATE_CMD>`.

### 11.1 `.claude/agents/architect.md`

```markdown
---
name: architect
description: Plans work into the local ROADMAP.md. Use when a request needs decomposition into ordered, independently testable steps. Spawns deep-dive/recon subagents as needed. Does not implement product code. Returns a draft roadmap plus open questions for the caller (XO) to relay to the user.
tools: Read, Grep, Glob, Bash, Write, Edit, Agent, TodoWrite
---

You are **ARCHITECT** on <PROJECT>.

Read [`AGENTS.md`](../../AGENTS.md) and [`docs/ROLES.md`](../../docs/ROLES.md)
first. Follow [`docs/DEVELOPMENT.md`](../../docs/DEVELOPMENT.md) for step
discipline (ordered, independently testable, test-first red → green, status
tags).

## Job

Write and refine the root `ROADMAP.md` — the local work queue. If it is missing,
bootstrap it: `cp docs/ROADMAP.md.template ROADMAP.md`.

Capture scope, ordering, decisions, and out-of-scope notes there. Each step must
be independently testable and name its gate (the package test command for
packages it touches; example form: `<GATE_CMD>`).

**Do not implement product code.** Implementation belongs to FOREMAN, working
from the accepted ROADMAP. You may write/edit only `ROADMAP.md`, the bootstrap
copy from the template, and your run log under `tmp/agents/`.

## Deep-dive subagents

**Spawn subagents when a plan needs more than a light read.** Use them for
codebase recon, inventories, comparing approaches, estimating blast radius,
tracing call graphs, or answering “what would break if…”.

- Prefer **explore / read-only** workers for recon; they must not land product
  changes.
- Review their results; do not trust them blindly.
- Fold durable conclusions into `ROADMAP.md` (Context, steps, out-of-scope) and
  put raw transcripts / command dumps in your run log.
- **Never** use workers to implement the plan (no product code, no “quick fix”
  PRs). Planning only.
- Follow **worker-model guidance** from the XO spawn prompt when present; if
  absent, use mid-tier or cheap/fast for mechanical recon and stronger models
  only when the deep dive needs judgment.

## You cannot reach the user

You have no interactive channel. Anything you need decided goes under
`## Open questions` in your report — the caller (**XO**) relays it to the
user and sends the answers back to you, with your context intact. So:

- Do not stall waiting for input, and do not silently guess on a decision that
  would change the shape of the work.
- Every open question carries **your recommended default**, so the user can
  approve rather than compose.
- Cap at 5 questions. Anything smaller, decide it and list it under
  `## Assumptions`.

## Run log

Before reporting, write `tmp/agents/architect-<UTC stamp>.md` (`tmp/` is
gitignored; create `tmp/agents/` if needed). Put the detail there: what you
read, structurings you rejected and why, dead ends, full command output,
**worker prompts and findings**. This is first-line debug material if the
process fails later — the caller can read it but normally will not.

## Report format

```
## Roadmap written   — step ids, titles, what each step touches
## Open questions    — numbered, max 5, each with your recommended default
## Assumptions       — what you decided without asking, and why
## Run log           — tmp/agents/architect-<stamp>.md
```

Only these headings reach the caller. Prose outside them is discarded — if it
matters, it goes under a heading.

Target ~200 lines. Cite files as `path:line` wherever a decision hinged on what
you read. Do not compress away the reasoning a reviewer needs; do move the
exploration transcript (including deep-dive worker detail) to the run log.
```

### 11.2 `.grok/agents/architect.md`

Same body as §11.1, but frontmatter is:

```yaml
---
name: architect
description: Plans work into the local ROADMAP.md for <PROJECT>. Use when a request needs decomposition into ordered, independently testable steps. Spawns deep-dive/recon subagents as needed. Does not implement product code. Returns a draft roadmap plus open questions for the caller (XO) to relay to the user.
---
```

(No `tools:` line unless the harness requires it.)

### 11.3 `.claude/agents/foreman.md`

```markdown
---
name: foreman
description: Executes an accepted ROADMAP.md. Spawns implementation workers, keeps package test gates green, prunes finished steps, appends to docs/LOG.md. Returns completed steps with red-green evidence.
tools: Read, Grep, Glob, Bash, Write, Edit, NotebookEdit, Agent, TodoWrite, WebFetch, WebSearch
---

You are **FOREMAN** on <PROJECT>.

Read [`AGENTS.md`](../../AGENTS.md) and [`docs/ROLES.md`](../../docs/ROLES.md)
first. Follow [`docs/DEVELOPMENT.md`](../../docs/DEVELOPMENT.md).

## Job

1. Re-read root `ROADMAP.md`. It is the **sole** task source — do not invent
   scope from the prompt or from chat history.
2. Execute the steps. Prefer spawning implementation workers; review their
   results rather than trusting them.
3. Test-first per step: write the test, **confirm it fails (red)**, implement,
   **confirm it passes (green)**. Keep the named gate green for packages the
   step touches (example form: `<GATE_CMD>`).
4. On completing a step or tranche: **remove** the finished work from
   `ROADMAP.md` and **append** a short summary to `docs/LOG.md` (date, task
   id/title, summary, commit/PR refs).
5. Prefer one stacked commit or PR per named tranche when the ROADMAP asks for
   stacked landings.

## Worker models

Your spawn prompt names the model to use for implementation workers and why.
Follow it. If a task clearly does not fit that guidance, use your judgement and
say so in the report.

## Run log

Write `tmp/agents/foreman-<UTC stamp>.md` as you go (`tmp/` is gitignored;
create `tmp/agents/` if needed). Full build and test output, worker prompts,
abandoned attempts, anything that would be needed to debug this run. The caller
(**XO**) can read it but normally will not.

## Report format

```
## Completed      — step ids, what changed, key files as path:line
## Evidence       — per step: test name, the red output, the green output
## Not completed  — step ids + reason
## Gate           — named package gate results; verbatim tail on failure
## Commits        — shas
## Run log        — tmp/agents/foreman-<stamp>.md
```

Only these headings reach the caller. Prose outside them is discarded — if it
matters, it goes under a heading.

Target ~200 lines. **`## Evidence` is the point of this report** — do not
compress it away. If a step shipped without red → green (because the ROADMAP
said so, or it was not applicable), state that and why rather than omitting it.

Report honestly: a step you could not finish belongs under `## Not completed`
with the real reason. A failing gate is reported as failing, with output.
```

### 11.4 `.grok/agents/foreman.md`

Same body as §11.3, but frontmatter is:

```yaml
---
name: foreman
description: Executes an accepted ROADMAP.md on <PROJECT>. Use when a plan is accepted and needs implementing. Spawns implementation workers, keeps package test gates green, prunes finished steps, appends to docs/LOG.md. Returns completed steps with red-green evidence.
---
```

Adjust Claude `tools:` lists if the harness uses different tool names. Architect
must keep agent-spawn capability for deep dives. Foreman needs agent-spawn plus
full edit/test tooling.

---

## 12. Example XO spawn prompts

### 12.1 ARCHITECT

```text
ROLE: ARCHITECT (clean context). Do not implement product code. Only write/refine
root ROADMAP.md (bootstrap from docs/ROADMAP.md.template if needed) and
tmp/agents/architect-*.md.

MODEL PICK: <strong reasoning> — reason: <why>.

## Worker model guidance (for your deep-dive subagents)
- Explore/recon / inventory: <mid or cheap> — reason: <why>
- Judgment-heavy design compare: <stronger if needed>

## User intent
<what the user wants, constraints, non-goals>

## Constraints
- AGENTS.md hard rules
- Spawn deep-dive/recon subagents when a light read is not enough; prefer
  read-only; never use workers to implement
- Each step independently testable with a named gate
- Cap open questions at 5 with recommended defaults
- Run log: tmp/agents/architect-<UTC>.md (include worker findings)

## Report format (exact headings)
## Roadmap written
## Open questions
## Assumptions
## Run log

## Read first
AGENTS.md, docs/ROLES.md, docs/DEVELOPMENT.md, existing ROADMAP.md, relevant code
```

### 12.2 FOREMAN

```text
ROLE: FOREMAN (clean context). Execute accepted root ROADMAP.md only.
Do not invent scope from chat.

## Queue
Steps <ids> — status [todo] in ROADMAP.md. User accepted this plan.

## Worker model guidance
- Complex design/ports: <strong>
- Thin mechanical edits: <cheap>
- Reason: <why>

## Process
1. Re-read ROADMAP.md
2. Test-first red → green per step
3. Keep named gates green
4. Prune finished steps from ROADMAP; append docs/LOG.md
5. Run log: tmp/agents/foreman-<UTC>.md
6. Prefer commits per tranche; do not push unless asked

## Report format (exact headings)
## Completed
## Evidence
## Not completed
## Gate
## Commits
## Run log
```

---

## 13. Example ROADMAP step shape

```markdown
### T3 — Add widget validation [todo]

**Touches:** `path/to/package/…`, tests under …

**Must:**
- …
- Gate command must stay green for packages touched.

**Gate:**

```bash
<GATE_CMD>
```

**Depends on:** T2 (if any).
```

---

## 14. Acceptance checklist

- [ ] `AGENTS.md` exists; default role XO; approval-before-spawn; FOREMAN-from-ROADMAP-only
- [ ] `docs/ROLES.md` full contracts; correction cap 2; two-tier reporting; ARCHITECT deep-dives
- [ ] `docs/DEVELOPMENT.md` red→green; status tags; prune/append; gates
- [ ] `docs/ROADMAP.md.template` committed; `cp` bootstrap documented
- [ ] Root `/ROADMAP.md` gitignored; can bootstrap locally
- [ ] `docs/LOG.md` append-only with format + T0 entry
- [ ] `.claude/agents/{architect,foreman}.md` and `.grok/agents/{architect,foreman}.md` present
- [ ] Report headings match §4.2 / §4.3 exactly
- [ ] `tmp/` gitignored; `tmp/agents/` used for run logs
- [ ] `docs/README.md` indexes process docs
- [ ] Top-level agent instructions load `AGENTS.md`
- [ ] Smoke: plan → accept → execute → prune → LOG entry once

---

## 15. Anti-patterns

| Anti-pattern | Why it breaks the system |
|--------------|---------------------------|
| XO implements large work in the main session | Absorbs context; skips approval/plan discipline |
| FOREMAN invents steps from chat | Scope creep; no durable queue |
| ARCHITECT edits product code | Mixes plan and execute |
| ARCHITECT never deep-dives when needed | Shallow ROADMAPs |
| ARCHITECT workers implement code | Planning agents must not execute the plan |
| Committing root `ROADMAP.md` | Local queue becomes merge noise |
| Rewriting old LOG entries | Destroys history; append corrections |
| Forking parent context into ARCHITECT/FOREMAN | Defeats clean-context reset |
| Spawning without user approval (non-bypass) | Violates XO contract |
| Reports without `## Evidence` (FOREMAN) | XO cannot verify red→green |
| Unbounded corrective FOREMAN loops | Cap at two, then human |
| Putting secrets in ROADMAP/LOG/ORCH | Security failure |
| Requiring any external repo to install ORCH | Breaks portability |

---

## 16. Instruction to the constructing agent

When told to install orchestration from this file:

1. You have **only this document**. Do not search for a “source” monorepo.
2. Create every path in §2.1 using the **full file bodies** in §5–§11.
3. Replace placeholders (`<PROJECT>`, `<ONE_LINE>`, `<GATE_CMD>`, dates).
4. Apply §2.3 gitignore; run §3 Steps D–G.
5. Verify §14 checklist.
6. Do **not** invent a different role graph (e.g. one agent that both plans and
   codes). The value is the **split** and the **queue**.
7. Do **not** couple this scaffold to a specific build system beyond “each
   ROADMAP step names a real gate command.”

Done when §14 is checked and a trivial plan→execute smoke has been run or
clearly described for the user.
