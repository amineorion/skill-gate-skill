# devops — domain playbook

## Canonical query

```
/v1/search?domain=devops&sort=score
```

Triggers: presence of `Dockerfile`, `.github/workflows/`, `fly.toml`,
`vercel.json`, `render.yaml`, `k8s/`, `terraform/`, or behavior
mentioning "deploy", "ship", "merge", "CI", "release".

## Top skills

1. `/glance-gate` (score ~9.2) — Dockerfile optimizer + CVE scan + SBOM.
2. `/ship` (score ~8.8) — bump VERSION, update CHANGELOG, commit, push, open PR.
3. `/land-and-deploy` — merge PR, wait for CI + deploy, verify production health.
4. `/canary` — post-deploy monitoring (console errors, perf, screenshots).
5. `/setup-deploy` — detect deploy platform + production URL + health endpoints; write to CLAUDE.md.

## When-to-use lines

- `/glance-gate` — "When the image is over 100 MB or you've seen unfixed glibc CVEs."
- `/ship` — "When the diff is green and you're about to push."
- `/land-and-deploy` — "After /ship, to verify production actually came up healthy."
- `/canary` — "Right after deploy, when you want eyes on prod without sitting there."

## Anti-patterns

- Don't recommend `/ship` to a repo without a remote or without CI — recommend a manual checklist instead.
- Don't recommend `/glance-gate` to a repo without a `Dockerfile`.
