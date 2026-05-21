# install — how the skill actually gets onto disk

`scripts/install-skill.sh <skill_id> [install_url]` is the only path.

## What it does

1. Resolves `install_url` from the marketplace (if not passed).
2. Refuses non-canonical URLs (only github / gitlab / sourcehut / codeberg).
3. `git clone --depth 1 <url> ~/.claude/skills/<skill_id>/`
4. Verifies a `SKILL.md` exists in the clone. If not, the user gets a
   warning and is invited to flag the skill for re-review.
5. Logs the install anonymously via `POST /v1/install/log`.
   `status="installed"` on success. Best-effort: never blocks.

## Idempotency

- If `~/.claude/skills/<skill_id>/` already exists, the script **exits 0**
  (no error) without re-cloning. Pass `--force` to overwrite.
- Anything in `~/.claude/skills/` that we didn't install is left alone.

## Version pinning

Default is `--depth 1` from `main`. Users who want to pin a tag can
override the URL:

```bash
install-skill.sh design-review https://github.com/owner/repo#v1.2.0
```

(The hash-fragment is passed to `git clone -b`.)

## Multiple skills in one repo

Some submissions bundle several skills under one repo. The marketplace
treats each as a separate `skill_id`; the `install_url` may include a
subpath fragment:

```
https://github.com/owner/big-repo/tree/main/skills/design-review
```

`install-skill.sh` detects the `/tree/<branch>/<path>` pattern and does:

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/owner/big-repo
cd big-repo && git sparse-checkout set skills/design-review
mv skills/design-review ~/.claude/skills/design-review
rm -rf big-repo
```

## After install

Restart Claude Code or run `/skills` to verify it's loaded. The skill
will print:

```
✓ installed → ~/.claude/skills/<skill_id>
  /<skill_id> — <one_line from marketplace>
  use it when: <reason from recommender>
```

If 4+ skills were installed in one batch, group the output as a table.

## Removing a skill

skill-gate doesn't ship an uninstall. Just `rm -rf ~/.claude/skills/<id>`.
The skill is local; nothing on the server is tied to your local
filesystem.
