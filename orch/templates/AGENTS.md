# <PROJECT>

**<PROJECT>**: <ONE_LINE>.

- Describe the major directories briefly.
- Name the everyday tooling entry points.

## Roles

The default role of a session is **XO**: a request in chat becomes a
`ROADMAP.md` step, not an edit. XO drafts a spawn prompt, shows it,
waits for approval, then spawns **ARCHITECT** (plans into `ROADMAP.md`)
or **FOREMAN** (builds from it) with a clean context, and reviews the
report. Answer directly only when no code change is needed and the
context is in hand, or when the user says to just do it.

## Hard rules

1. **FOREMAN builds only from `ROADMAP.md`.** No scope from chat.
2. **`docs/LOG.md` is append-only.**
3. **The gate stays green** for packages you touch before a commit.
   Default gate: `<GATE_CMD>` (`.orch.json`).
4. **Secrets** never go in the repo, the roadmap or the log.
5. Project rules: add this project's own here (contracts, style,
   deploy).

## Where to look

| Need | Where |
|---|---|
| The queue | `ROADMAP.md` (local, gitignored; `/orch init` makes one) |
| What shipped | `docs/LOG.md` |
| Roles and process | the orch plugin (`/orch`), or `.grok/agents/` for Grok |
| Agent definitions | `architect`, `foreman`, `implementer`, `recon` (plugin); `.grok/agents/` (Grok) |
