# marketing — domain playbook

## Canonical query

```
/v1/search?domain=marketing&sort=score
```

Use when the user says any of: "marketing", "copy", "landing", "launch",
"tweet", "pitch", "homepage", "brand", "voice".

## Top skills (typical ranking)

1. `/marketing-copy` (score ~8.6) — drafts landing-page copy, ad variants, launch tweets from a product description.
2. `/landing-page` (score ~8.2) — complete landing page (HTML/CSS, no build) from a paragraph of pitch.
3. `/launch-thread` — twitter / linkedin launch threads.
4. `/seo-audit` — meta tags, schema.org, OG / Twitter cards, sitemap.

## When-to-use lines (use these verbatim when recommending)

- `/marketing-copy` — "When you have a product but no copy yet, or want A/B variants."
- `/landing-page` — "When you need a marketing page tonight and don't want to bring in a build step."
- `/launch-thread` — "When you're shipping in a week and need 4 tweet variants ready."
- `/seo-audit` — "When the homepage already exists and you want the search-engine basics covered."

## Anti-patterns

- Don't recommend marketing skills inside CLI / library / SDK repos
  unless the user explicitly asks. The signal "no UI, no landing page,
  README is the front door" is strong.
- Don't recommend `/landing-page` if a `next` / `astro` / `vite` site
  already exists — recommend `/design-review` + `/marketing-copy`
  instead.

## What to suggest after install

> Try `/marketing-copy "<one-paragraph product pitch>"` for the first
> draft. The skill will ask for tone references (a URL of an existing
> site you like) before writing.
