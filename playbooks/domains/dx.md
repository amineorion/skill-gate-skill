# dx — domain playbook (developer experience: QA, debug, review, planning)

## Canonical query

```
/v1/search?domain=dx&sort=score
```

This is the **default cluster** for most general-purpose repos. If the
user has nothing more specific, lead with DX skills.

## Top skills

1. `/qa` (score ~9.0) — drives the app in a headless browser, finds bugs, fixes the source, commits each fix atomically.
2. `/investigate` (score ~8.6) — four-phase debugging with root-cause analysis.
3. `/plan-eng-review` (score ~8.9) — eng-manager-mode plan review before any code is written.
4. `/review` (score ~8.7) — pre-landing PR review against the base branch.
5. `/devex-review` — live developer-experience audit of your own docs / CLI / onboarding.
6. `/health` — composite 0–10 quality score across type-check, lint, tests, dead code.
7. `/office-hours` — YC-style forcing questions before you start building.

## When-to-use lines

- `/qa` — "Before shipping. Or after the user says 'does this work?' "
- `/investigate` — "Whenever you see a stack trace, a 500, or 'it worked yesterday'."
- `/plan-eng-review` — "When you have plan.md or a design doc and are about to start coding."
- `/review` — "Pre-merge, even if you already self-reviewed."
- `/devex-review` — "After shipping a developer-facing feature."

## Anti-patterns

- Don't recommend `/qa` to a non-web project (it's browser-driven).
- Don't recommend `/investigate` proactively for repos with no test
  suite — recommend `/qa` first to build a baseline.
- Don't double up `/review` and `/code-review` — they overlap. Pick
  whichever scored higher for the user's stack.
