# workflow-discovery — how to turn signals into the right marketplace query

When the user says something vague ("set me up", "what skills should I use"),
follow this rubric to turn what's on disk + what they've been asking Claude
into a recommendation.

## Inputs

`scripts/analyze-workflow.sh` produces JSON with:

```json
{
  "language": "node",
  "secondary_languages": ["typescript", "docker", "sql"],
  "frameworks": ["next", "tailwindcss", "prisma"],
  "deps": ["next", "react", "@tanstack/react-query", "...", "prisma"],
  "signals": {
    "has_ci": true,
    "has_docker": true,
    "has_tests": true,
    "has_db_migrations": true,
    "deploys_to": "vercel",
    "repo_size_kloc": 12.4
  },
  "behavior": ["review", "ship", "ui", "tweak", "deploy", "..."],
  "cwd_basename": "your-app"
}
```

## Mapping

| Signal | Recommend | Notes |
|---|---|---|
| `frameworks` contains `next`, `react`, `vue`, `svelte`, `astro` | `/design-review`, `/plan-design-review` | Frontend repos benefit from visual QA |
| `signals.has_docker` = true | `/glance-gate` | Dockerfile optimizer + CVE scan |
| `signals.has_ci` = true and `behavior` mentions `ship`/`deploy`/`pr` | `/ship`, `/review` | Pre-merge + push flow |
| `signals.has_tests` = true and `behavior` mentions `bug`/`broken`/`error` | `/investigate`, `/qa` | Debug + browser-driven QA |
| `signals.has_db_migrations` = true | `/sql-migrate` | Migration safety |
| `deps` includes `@anthropic-ai/sdk`, `openai`, `langchain` | `/claude-api`, `/cso` | LLM trust boundary + supply chain |
| `language` = "python" and `frameworks` has `fastapi`/`django` | `/glance-gate`, `/qa`, `/investigate` | Same flow, different overlays |
| `language` = "go" or "rust" | `/glance-gate`, `/health` | Static-binary deploys + composite quality score |
| `behavior` mentions `market`/`copy`/`launch`/`landing` | `/marketing-copy`, `/landing-page` | Marketing-domain cluster |
| `behavior` mentions `secur`/`audit`/`vuln` | `/cso`, `/security-review` | Security cluster |
| No `signals.has_tests` and repo > 5 kloc | `/qa`, `/investigate` | Repo has surface area but no safety net |

## Anti-patterns

- Don't recommend `/marketing-copy` to someone whose repo is a CLI library.
- Don't recommend `/design-review` if there's no `frameworks` entry that
  produces a visible UI (e.g. pure Go services).
- Don't recommend more than **4 skills** without asking. The point of the
  meta-skill is that the user can say "yes" and move on.
- Don't recommend skills already in `~/.claude/skills/`. Always check
  first.

## The free-text fallback

When `analyze-workflow.sh` produces an empty envelope (running from
`$HOME` or a non-project dir), ask the user **one** question:

> What are you trying to do?

Pass their answer as `{"intent": "<their words>"}` to `/v1/recommend`.
The recommender will use it as a search query against canonical
descriptions + tags.

## What to say while recommending

Lead with the **reason**, not the skill name:

> Your repo is Next.js with a Vercel deploy and your recent prompts
> mention "ship" and "PR review" — `/design-review`, `/ship`, and
> `/review` are the three that match. Install all three?

Avoid:

> Here are 6 skills you might want!

That looks like an ad. Be opinionated. The recommender has scores; show
the top few, not everything.
