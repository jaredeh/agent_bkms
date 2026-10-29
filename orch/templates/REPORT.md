# <step id> — <step title>

_<YYYY-MM-DD>. Built by FOREMAN. Commits: <shas>. Gate: <green | red, command>._

One report per roadmap step, written by FOREMAN into `docs/reports/`
(gitignored, like `ROADMAP.md`). `docs/LOG.md` is the one-line durable
history; this is the human-readable one: what was done, in prose, and
every judgment call a reviewer should get to overturn.

## What was done

A short recap for a person, not a changelog: what the step asked for,
how it was approached, what changed and where (`path:line`), what was
tested and how. A paragraph or two. Anything not finished, and why.

## Assumptions

A judgment call that the step, the roadmap, the user and the existing
code did not settle, where another engineer could reasonably have gone
the other way, or where confidence was less than high. Leave out what
the step or the code dictated. Collected from every implementer that
worked the step, plus FOREMAN's own. Number them; "none" is a valid
entry, but say it.

### A1 — <short name for the call>

**Context:** why this came up: the part of the step or the code that
forced a choice (`path:line`).
**Question:** the one question that had to be answered.
**Decision:** what was chosen, and where it lives (`path:line`).
**Alternatives:** each option considered, one line each, and why it
was rejected.
**Confidence:** high / medium / low, and what would change the answer.

### A2 — …
