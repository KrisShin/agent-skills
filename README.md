# agent-skills

Four agent skills, plus everything needed to install them on another machine.

Written from a working install on DSH 0.2.1-rc.3 (Windows), verified by cloning into a clean
directory and re-installing. Where a step depends on the host, this file names the host and the
version it was checked against, so a different agent can tell what to re-verify.

---

## 1. What these are

Plain Markdown. No build step, no dependencies, no runtime.

| Skill | Invocation | What it does |
| --- | --- | --- |
| `ship` | `/ship` only | Runs a whole delivery: grill → spec → tickets → test-first build → three-axis review → close-out. Keeps state in `.scratch/<slug>/`. |
| `grilling` | auto or `/grilling` | Interviews you about a plan or design until nothing is silently assumed. |
| `tdd` | auto or `/tdd` | Red→green loop at agreed seams, plus the anti-patterns that make tests worthless. |
| `diagnosing-bugs` | auto or `/diagnosing-bugs` | Bounded diagnosis loop for hard bugs, gated on a feedback loop that goes red. |

`ship` declares `disable-model-invocation: true`, so it is **absent from the model's tool catalog**.
Only the `/` menu reaches it; `skill("ship")` failing is correct behaviour, not a broken install.

The other three are reachable both ways: the agent may fire them on its own, and you may type them.

---

## 2. Where a host looks for skills

This is the part that decides whether an install works at all, so it comes before the instructions.

DSH resolves skills through `@deepseek-ai/dsh-skill-filesystem`, which scans these roots in rank
order (lower rank wins when a name collides):

| Rank | Source | Path |
| --- | --- | --- |
| 100 | `project-dsh` | `<projectRoot>/.dsh/skills` |
| 200 | `project-agents` | `<projectRoot>/.agents/skills` |
| 300 | `custom` | the provider's `customSkillDirs` config |
| 400 | `user-dsh` | `<dshHome>/skills` (default `~/.dsh/skills`) |
| 500 | `user-agents` | `<agentsHome>/skills` (default `~/.agents/skills`) |
| 600 | bundled | `$DSH_BUNDLED_SKILL_DIR`, when configured |

`<projectRoot>` is the nearest ancestor containing `.git`; with no repository it is the current
working directory.

Two consequences worth knowing:

- **A skill placed in a project root is scoped to that project.** `.agents/skills` inside a repo is
  only visible when working in that repo.
- **`~/.agents/skills` is the user-wide root.** It is what this repo targets, and what the install
  step below writes to.

A skill is a directory `<name>/SKILL.md`, or a flat `<name>.md`. Nested `**/SKILL.md` below the
top level is **not** discovered — which is why `ship/references/*.md` are resources, not skills.

Frontmatter fields DSH understands: `name` and `description` (required), plus `whenToUse`,
`metadata`, `disable-model-invocation`, `user-invocable`.

---

## 3. Install

### 3.1 Clone

```bash
git clone https://github.com/KrisShin/agent-skills.git ~/agent-skills
```

### 3.2 Copy into the user skills root

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

Or just run the script, which does the pull and the copy together and is safe to re-run:

```bash
./scripts/install.sh        # from the repo root
```
```powershell
.\scripts\install.ps1
```

### 3.3 Restart, then verify

DSH watches the roots, so a *new* skill usually appears without a restart. Do not rely on it: the
caches in play differ per host and per session, and a restart costs nothing.

Verification that actually proves something, in order of strength:

1. **Load one skill and read the result.** `grilling` is the cheap one: it is model-invocable, so
   any agent can call it and see the body come back.
2. **Check the file is where the host looks.** `ls ~/.agents/skills/grilling/SKILL.md`.
3. **For `ship`, confirm it is *not* model-invocable.** Asking the skill loader for `ship` should
   fail with "not available for model invocation". That failure is the feature.

Do not "verify" by checking that a directory exists. Existence proves nothing about discovery.

---

## 4. Why this install copies instead of symlinking

Symlinking looks tidier and DSH itself supports it — the provider docs say catalog entries "expose
the resolved instruction-file path, so symlinked directories and flat files can open as regular-file
previews".

It still breaks, and this was measured on the reference install:

```
ops_glob ~/.agents/skills/ship/references/
→ rejected: PATH_RESTRICTED
→ "Links, reparse points and special objects are not traversed"
```

`ops_*` in [dsh-ops](https://github.com/T-Auto/dsh-ops) refuses to traverse symlinks, junctions and
reparse points as a security property. `ship` reads `references/review.md` at Stage 5 and
`references/close.md` at Stage 6, so a linked install makes `/ship` fail at exactly the stages that
matter.

**Copy.** If the host has no `ops_*` tools (plain DSH without dsh-ops, or another agent runtime),
symlinks are fine — but copying works everywhere, so it is the default here.

---

## 5. Line endings are part of the contract

`.gitattributes` pins `* text=auto eol=lf`. Without it, a Windows checkout with the common
`core.autocrlf=true` rewrites every file to CRLF and the bytes differ from the reference install:

| | bytes |
| --- | --- |
| LF (correct) | 2166 |
| CRLF (what you get without `.gitattributes`) | 2204 |

Skills are read by agents that compare text literally, so this is not cosmetic. Keep the file.

`*.sh` is forced to LF (it must run on POSIX) and `*.ps1` to CRLF (PowerShell tolerates either, but
CRLF is what Windows editors produce).

---

## 6. Updating

```bash
cd ~/agent-skills && git pull && ./scripts/install.sh
```

The installer replaces each destination wholesale, so an edit made directly in
`~/.agents/skills` is lost. Edit here, then re-run the installer.

---

## 7. Adding a skill to this repo

1. Create `<name>/SKILL.md` at the repo root with `name` and `description` in the frontmatter.
2. Add `<name>` to the `skills` array in **both** `scripts/install.sh` and `scripts/install.ps1`.
   They keep their own lists; adding to one and not the other is the obvious failure.
3. Commit. `git pull && ./scripts/install.sh` on each machine.

Do not add a skill by dropping it into a nested directory — the provider only scans the top level of
each root.

---

## 8. What is not here

`tabbit` is installed at `~/.agents/skills/tabbit` on the reference machine but is **excluded from
this repo**. It carries a `.tabbit-dance-managed` marker: a third-party installer owns it, and
copying or linking it breaks that installer's own update path. Install it separately, the way its
provider documents.

---

## 9. Reference environment

Everything above was verified on:

| | |
| --- | --- |
| Host | DeepSeek Harness `0.2.1-rc.3` |
| OS | Windows 11 |
| Skills root used | `%USERPROFILE%\.agents\skills` |
| File tools present | `dsh-ops@0.4.1` (this is what made symlinks fail) |

On a host without `dsh-ops`, section 4's constraint does not apply. On a host that is not DSH, the
root table in section 2 is DSH-specific — check that agent's own documentation for where it reads
skills, then keep the copy-based install.
