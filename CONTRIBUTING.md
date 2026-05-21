# Contributing to skill-gate

Thanks for thinking about contributing. Most useful contributions:

## 1. Domain playbooks

Each file under [`playbooks/domains/`](playbooks/domains/) covers one
cluster (frontend, devops, security, data, marketing, dx). They follow
the same shape:

```
# <domain> — domain playbook
## Canonical query
## Top skills
## When-to-use lines
## Anti-patterns
```

Add a new domain by creating `playbooks/domains/<name>.md` and adding
a `[[<name>]]` link from `SKILL.md`.

## 2. Detection rules

`scripts/analyze-workflow.sh` emits the JSON the recommender uses.
Add new framework detectors, deploy targets, or behavior verbs to the
existing `detect_*` functions. The only hard rule: **never read outside
the cwd, never include private-looking dep names** (use the
`PUBLIC_SCOPES` heuristic).

## 3. Bug reports

Open an issue with:

- The cwd's `package.json` / `pyproject.toml` / `go.mod` / etc. (redact
  private deps).
- The output of `scripts/analyze-workflow.sh`.
- What you got back from `/v1/recommend` and why it was wrong.

## 4. Style

- Bash: `set -euo pipefail` at the top of every script. No bashisms
  that break on macOS `/bin/bash` 3.2.
- Markdown: 80-char soft wrap. Lead with the verb in section titles
  ("Mapping", not "Workflow → marketplace mapping").

## License

By contributing you agree your contribution is Apache 2.0.
