# agent_bkms

Best-known methods for working with coding agents. One plugin so far:

## orch

XO / ARCHITECT / FOREMAN orchestration for Claude Code, as a plugin:
plan in a clean context, build from a written queue, keep an
append-only log, and let hooks enforce the mechanical rules.

```
/plugin install orch --marketplace jaredeh/agent_bkms
```

Then, in a repo:

```
/orch init          # .orch.json, ROADMAP.md and docs/reports/ (gitignored), docs/LOG.md, AGENTS.md, CLAUDE.md lines
/orch               # the roles, and what the session does next
/orch plan <ask>    # draft the ARCHITECT spawn; show it; spawn at once
/orch build T1 T2   # draft the FOREMAN spawn for accepted steps; wait for approval; spawn
/orch run <ask>     # plan then build, no approval stops; defaults taken, reported at the end
/orch status        # the queue and the last log entries
```

### What's in it

| | |
|---|---|
| `orch/agents/` | `architect` (plans, Opus), `foreman` (builds, Opus), `implementer` (one step, Sonnet), `recon` (read-only, Sonnet). Models pinned per agent; override per spawn. |
| `orch/skills/orch/` | the `/orch` command: init, status, plan, build, and the XO contract |
| `orch/hooks/` | the gate runs before every `git commit` and blocks on failure; `docs/LOG.md` is append-only; `ROADMAP.md` and `docs/reports/` are never staged; a session-start reminder of the role and the queue |
| `orch/docs/` | `ROLES.md`, `DEVELOPMENT.md`: the contracts and the discipline |
| `orch/templates/` | what `/orch init` writes into a repo, including `.grok/agents/` for Grok |

### What changed from the 2026-08 blueprint

The original, `legacy/ORCH-2026-08.md`, was a 1,000-line document an
agent re-typed into each repo. The roles, the queue, the fixed report
headings, mandatory Evidence, questions capped at five with defaults,
and the two-round correction cap are unchanged. What moved:

- **Packaging.** Agents, hooks, docs and templates live in the plugin;
  a repo gets five small files from `/orch init`.
- **Hooks instead of prose** for the rules a script can check.
- **Models pinned in agent files**, not passed as text. Worker agents
  (`implementer`, `recon`) are defined, so FOREMAN and ARCHITECT don't
  improvise them.
- **Continuity is a mechanism**: XO messages the same ARCHITECT with
  answers (SendMessage) instead of re-spawning.
- **`CLAUDE.md` imports `AGENTS.md`**, so Claude Code and Grok read one
  set of rules.
- Plan mode is for XO's direct work; the Workflow tool is an option for
  FOREMAN fan-out when the user opts in; the memory directory is the
  agent's notes, not the project log.
- **Step reports** (new): every built step leaves
  `docs/reports/<date>-<id>-<slug>.md`, gitignored, with a recap for a
  person and the assumptions made along the way, each as context,
  question, decision, alternatives and confidence. The list you used to
  have to ask for.

What's still prose, because only a model can judge it: don't invent
scope, cap corrective rounds, show the prompt, and wait before building.
