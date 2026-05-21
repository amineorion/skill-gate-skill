# skill-gate

> Install one skill. Ask Claude to add the rest based on what you're building. Open source.

`skill-gate` is a [Claude Code](https://docs.claude.com/en/docs/claude-code) skill that bridges Claude to the **skill-gate marketplace** — a curated, AI-reviewed, admin-accepted catalogue of Claude Code skills.

Two flows:

1. **Set me up** — reads your project (language, frameworks, public deps, deploy target) plus a small abstracted bag of recent prompts, and installs the skills that match. Prints a one-line usage explainer per skill.
2. **Find me a skill for X** — searches the marketplace by domain or keyword, shows AI-reviewed descriptions and scores.

License: **Apache 2.0**.

## Install

```bash
git clone https://github.com/amineorion/skill-gate-skill.git ~/.claude/skills/skill-gate
# restart Claude Code, then type /skills to verify
```

You should see `skill-gate` in the list.

## Use

In any project:

```
/skill-gate set me up based on what I'm working on
```

Or, for a specific need:

```
/skill-gate find me a skill for marketing copy
```

skill-gate will:

1. Detect the language, frameworks, public deps, deploy target.
2. (Best effort) Read your recent Claude Code prompts for behavior signals — abstracted to verbs/nouns, never the full text.
3. Call `POST /v1/recommend` on the marketplace.
4. Show top recommendations, grouped by domain, with reasons.
5. After your okay, `git clone` each into `~/.claude/skills/<id>/`.
6. Print a one-line **when-to-use** for each installed skill.

## File layout

```
skill-gate-skill/
├── SKILL.md                       # entry — Claude Code loads this
├── LICENSE                        # Apache 2.0
├── playbooks/
│   ├── workflow-discovery.md      # signals → marketplace query mapping
│   ├── install.md                 # install flow detail
│   └── domains/                   # one playbook per cluster
│       ├── frontend.md
│       ├── devops.md
│       ├── security.md
│       ├── data.md
│       ├── marketing.md
│       └── dx.md
├── scripts/
│   ├── skill-gate-api.sh          # device auth + all /v1/* calls
│   ├── analyze-workflow.sh        # produces workflow-signals JSON
│   ├── install-skill.sh           # idempotent install into ~/.claude/skills/
│   └── submit-skill.sh            # community submit / request flow
└── templates/                     # (reserved for future skill scaffolds)
```

## Trust model

- skill-gate **never reads files outside the project working directory**.
- All AI inference runs in **your** Claude Code session against **your** Anthropic key.
- **One outbound call** per session: `/v1/recommend` or `/v1/search`. Body is anonymized signals (language, framework names, public dep names). Source code is never uploaded.
- Installs are `git clone` from canonical URLs (github / gitlab / sourcehut / codeberg). You can inspect each on `https://skill-gate.dev/skills/<id>` first.
- Every accepted skill was AI-reviewed for prompt-injection patterns, shell-out safety, and outbound network. The review is published with the skill.

## Configuration

| Env | Default | Purpose |
|---|---|---|
| `SKILL_GATE_API` | `https://api.skill-gate.dev` | Override the API base URL (self-host, dev cluster) |
| `SKILL_GATE_NO_BEHAVIOR` | `0` | Set to `1` to skip the recent-prompts behavior scan |

## Submitting a skill

Build your own skill and want it in the catalogue?

```
/skill-gate submit https://github.com/you/your-skill frontend
```

Or in the [landing page](https://skill-gate.dev/#request) form.

The submission goes through an AI review (~30s) and then an admin queue.
Accepted skills appear in the marketplace with attribution.

## Contributing to skill-gate itself

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Most useful contributions:

1. **Domain playbooks** under [`playbooks/domains/`](playbooks/domains/).
2. **Detection rules** in [`scripts/analyze-workflow.sh`](scripts/analyze-workflow.sh) — new frameworks, deploy targets, behavior verbs.
3. **Bug reports** with the input repo and the bad recommendation.

## License

Apache 2.0. See [`LICENSE`](LICENSE).
