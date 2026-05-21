# frontend — domain playbook

## Canonical query

```
/v1/search?domain=frontend&sort=score
```

Use when the user's repo shows `next` / `react` / `vue` / `svelte` /
`astro` / `solid`, or behavior mentions: "ui", "design", "css", "polish",
"layout", "responsive", "tailwind".

## Top skills

1. `/design-review` (score ~9.1) — visual QA on a live URL; finds spacing, hierarchy, slop; fixes them in source with before/after screenshots.
2. `/plan-design-review` (score ~8.5) — designer's-eye plan review before any code is written.
3. `/design-shotgun` — generates multiple AI design variants, opens a comparison board.
4. `/design-consultation` — produces a DESIGN.md for new projects.
5. `/qa` — drives the app in a headless browser and fixes the bugs.

## When-to-use lines

- `/design-review` — "After deploying, when you want a designer to walk the site."
- `/plan-design-review` — "When the plan has UI components and you want them rated 0–10 before coding."
- `/design-shotgun` — "When you have a feature description but no clear visual direction."

## Anti-patterns

- Don't recommend `/design-shotgun` to a project with an existing design
  system — use `/design-review` against the live site instead.
- Don't recommend `/design-consultation` for an existing site with a
  visible aesthetic — recommend `/plan-design-review` or
  `/design-review` to refine what's there.
