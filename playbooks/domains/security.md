# security — domain playbook

## Canonical query

```
/v1/search?domain=security&sort=score
```

Triggers: behavior mentions "secur", "audit", "vuln", "cve", "leak",
"secret", "auth", "owasp"; or repo has `.env*`, `secrets/`, IAM configs,
LLM SDK deps.

## Top skills

1. `/cso` (score ~8.7) — Chief security officer mode; daily + comprehensive audit modes.
2. `/security-review` — complete security review of pending branch changes.
3. `/glance-gate` (cross-listed from devops) — image hardening + CVE scan.
4. `/review` — pre-landing PR review, catches LLM trust-boundary violations and SQL safety.

## When-to-use lines

- `/cso` — "Once a week / before raising money / before a customer audit."
- `/security-review` — "On every branch before landing — daily mode is zero-noise."
- `/review` — "Pre-merge — catches the structural issues a security tool misses."

## Anti-patterns

- Don't recommend `/cso` daily mode to a 1-person side project — it's
  for repos with an actual prod surface.
- Don't recommend security skills as the user's *first* installs unless
  they explicitly asked. Lead with DX / shipping / debug; security
  becomes urgent after the user has something to lose.
