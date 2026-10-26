# agent-skills

My Claude/DSH agent skills. Plain Markdown — no build step, no dependencies.

## What's here

| Skill | Invocation | What it does |
| --- | --- | --- |
| `ship` | `/ship` only | Runs a whole delivery: grill → spec → tickets → test-first build → three-axis review → close-out. Keeps state in `.scratch/<slug>/`. |
| `grilling` | auto or `/grilling` | Interviews you about a plan or design until nothing is silently assumed. |
| `tdd` | auto or `/tdd` | Red→green loop at agreed seams, plus the anti-patterns that make tests worthless. |
| `diagnosing-bugs` | auto or `/diagnosing-bugs` | Bounded diagnosis loop for hard bugs, gated on a feedback loop that goes red. |

`ship` is `disable-model-invocation: true`, so it is **not** in the model's catalog — only the `/` menu reaches it. The other three are reachable both ways.

## Install on a new machine

Skills are read from `~/.agents/skills/<name>/SKILL.md`.

```bash
git clone <this-repo> ~/agent-skills
```

**Copy, do not symlink.** This is not a style preference:

> DSH's `ops_*` file tools refuse to traverse symlinks, junctions, and reparse points (`PATH_RESTRICTED`, "Links, reparse points and special objects are not traversed"). A linked skill directory therefore breaks whenever a skill reads its own `references/` — `ship` does exactly that at Stage 5 and 6.

```bash
# macOS / Linux
mkdir -p ~/.agents/skills
cp -R ~/agent-skills/{ship,grilling,tdd,diagnosing-bugs} ~/.agents/skills/
```

```powershell
# Windows
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills" | Out-Null
foreach ($d in 'ship','grilling','tdd','diagnosing-bugs') {
  Copy-Item -Recurse -Force "$env:USERPROFILE\agent-skills\$d" "$env:USERPROFILE\.agents\skills\$d"
}
```

The trade-off is that copying does not auto-update. Update with the scripts below rather than by hand, so the copy stays complete.

## Updating

```bash
cd ~/agent-skills && git pull
```

Then re-copy — `scripts/install.sh` / `scripts/install.ps1` do the pull and the copy together, and are safe to re-run.

```bash
./scripts/install.sh          # macOS / Linux, from the repo root
```
```powershell
.\scripts\install.ps1         # Windows, from the repo root
```

Because copying replaces the destination, a local edit you made directly in `~/.agents/skills` will be lost on update. Edit here, then re-run the installer.

## Not included

`tabbit` lives in `~/.agents/skills/tabbit` but is managed by a third-party installer (`.tabbit-dance-managed`). Syncing it breaks its own update mechanism, so it is deliberately excluded.
