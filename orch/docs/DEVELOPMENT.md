# Development process

Work ships as ordered, independently testable steps, often grouped into
named tranches. The queue is `ROADMAP.md`; this is the discipline for
every step in it. Roles: [ROLES.md](ROLES.md). What shipped:
`docs/LOG.md` in the project.

## Rules

- Each step updates tests, docs and whatever else the change touches.
- After a step, the named gate for the packages it touches is green.
- Changing a public API or shared contract: update the contract source
  first, regenerate consumers, then land handlers, clients and tests
  together.
- The plugin's hook runs the project's default gate (`.orch.json`)
  before every `git commit` and refuses the commit if it fails.
  `ORCH_SKIP_GATE=1` skips it; say why in the report.

## Gates

There is usually no repo-wide mega-test. Each roadmap step names the
gate for the packages it touches: the package's everyday test command.
The project's default is in `.orch.json`.

## Test-first: red then green

1. Write the test asserting the wanted behaviour.
2. Run it; confirm it fails (red). Keep the gate green for unrelated
   packages meanwhile (packages, build tags or skip markers until the
   step lands).
3. Implement until it passes (green); the test joins the package's
   always-on suite.
4. No step is done without its test in that suite.

| Tag | Meaning |
|---|---|
| `[todo]` | Not started |
| `[impl]` | Code present; always-on test still pending |
| `[done]` | Shipped with the gate green; pruned from the roadmap |

When a tranche ships, prune its steps from `ROADMAP.md`. Detail lives in
git, `docs/LOG.md`, the tests that pin the behaviour, and the local step
report in `docs/reports/` (recap plus the assumptions made).

## Roadmap shape

1. The preamble from the template.
2. `## Context`: locked decisions, the slice, links.
3. `## Remaining work`: ordered steps with ids, touches, gates, tags.
4. `## Out of scope`
5. `## Deferred`

## LOG shape

Append-only, newest at the bottom, corrections appended rather than
edited in. A hook refuses rewrites.

```markdown
## YYYY-MM-DD — T3 Add widget validation

- What shipped, in a few lines
- Commits: abc1234
```
