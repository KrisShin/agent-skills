# agent-skills

Four agent skills of my own, plus pointers to the external DSH plugins I run. Everything needed
to install them on another machine lives here.

Written from a working install on DSH 0.2.1-rc.3 (Windows), verified by cloning into a clean
directory and re-installing. Where a step depends on the host, this file names the host and the
version it was checked against, so a different agent can tell what to re-verify.

---

## 1. What is in here

`catalog.tsv` is the single source of truth. Both installers read it, so adding an entry is one
edit rather than two. Two kinds of entry live in it:

**Local skills** — plain Markdown, shipped in this repo, copied into the skills root.

| Skill | Invocation | What it does |
| --- | --- | --- |
| `ship` | `/ship` only | Runs a whole delivery: grill → spec → tickets → test-first build → three-axis review → close-out. Keeps state in `.scratch/<slug>/`. |
| `grilling` | auto or `/grilling` | Interviews you about a plan or design until nothing is silently assumed. |
| `tdd` | auto or `/tdd` | Red→green loop at agreed seams, plus the anti-patterns that make tests worthless. |
| `diagnosing-bugs` | auto or `/diagnosing-bugs` | Bounded diagnosis loop for hard bugs, gated on a feedback loop that goes red. |

**External plugins** — nothing is vendored, forked, or copied. The catalog records the upstream
open-source repo and a verified package spec; the installer prints the link and the commands and
**never runs them**.

| Plugin | Upstream | Verified on |
| --- | --- | --- |
| `dsh-ops` | [T-Auto/dsh-ops](https://github.com/T-Auto/dsh-ops) | DSH 0.2.1-rc.3 |
| `dsh-connect-workbuddy` | [dingminhua/dsh-connect-workbuddy](https://github.com/dingminhua/dsh-connect-workbuddy) | DSH 0.2.1-rc.3 |

Why external plugins are not installed here: they are npm packages with their own peer-range gates,
their own upgrade cadence, and their own risk surface. Pinning a copy in this repo would silently
freeze them and hide upstream's security fixes. A link and a command go stale honestly; a vendored
copy goes stale silently.

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

### 3.2 Run the installer

```bash
./scripts/install.sh        # macOS / Linux (from the repo root)
```
```powershell
.\scripts\install.ps1       # Windows
```

The installer is **interactive and never installs anything you did not pick**:

1. It reads `catalog.tsv` and checks what is already present — a local skill counts as installed
   when `<skillsRoot>/<name>/SKILL.md` exists; an external plugin counts as installed when its
   package is in the profile's `node_modules` **and** listed in `dsh.profile.bundles`, which is what
   actually loads it.
2. It prints `Already installed (skipped)` with that list.
3. It prints only the **not-yet-installed** entries, numbered.
4. It asks once: `1,3` / `all` / Enter to cancel.
5. Local selections are copied. External selections print their repo link and commands; the script
   stops there and does not invoke `dsh`, `npm`, or `pnpm`.

Selection can also be passed as arguments, which skips the prompt — useful for automation and for
re-running one skill:

```bash
./scripts/install.sh ship grilling
./scripts/install.ps1 tdd
```

A name that is already installed is reported and skipped rather than reinstalled. A name that is not
in the catalog is an error, even when there is nothing left to install — a typo must not look like
success.

### 3.3 External plugins, if you chose any

The script prints them; run the commands yourself. For each one:

```sh
dsh plugin --profile desktop add dsh-ops@0.4.1
```

Two things to know, both measured on this host:

- **Quit DeepSeek Harness first.** The `desktop` profile is owned by the running application; the
  CLI refuses to touch it while the app holds it. Start the app again afterwards.
- **A peer-range gate may refuse the install.** On DSH `0.2.1-rc.3` both plugins declare ranges that
  exclude rc releases, so the profile skips the bundle entirely and the UI shows nothing. The fix is
  an explicit, exact-version exemption — never edit the plugin's `package.json`:
  ```sh
  dsh plugin --profile desktop allow-version dsh-ops@0.4.1 --dsh-version 0.2.1-rc.3 --accept-risk
  ```
  Exemptions live in the profile's `compatibility.json` and are keyed by exact version, so a DSH
  upgrade needs the grant repeated.

### 3.4 Restart, then verify

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

The installer replaces each local destination wholesale, so an edit made directly in
`~/.agents/skills` is lost. Edit here, then re-run the installer.

`git pull` failing on uncommitted changes is expected and not fatal: the installer warns and
installs from the working tree, so you can edit a skill and publish it in one step.

---

## 7. Adding an entry to this repo

Everything starts in `catalog.tsv` — the installers have no list of their own.

**A local skill:**

1. Create `<name>/SKILL.md` at the repo root with `name` and `description` in the frontmatter.
2. Add a `local|<name>|<dir>|-|-|<description>` row to `catalog.tsv`.
3. Commit. `git pull && ./scripts/install.sh` on each machine.

**An external plugin:**

1. Add an `external|<name>|<repo-url>|<pkg-spec>|<verified-dsh-version>|<description>` row.
2. Verify the spec on a real host — install it, confirm it actually loads, and note the DSH version
   you did that on. `-` means "not verified yet"; do not claim a version you did not run.
3. Commit. The installer will offer it to machines that do not have it yet.

Do not add a skill by dropping it into a nested directory — the provider only scans the top level of
each root. Do not vendor an external plugin: a pinned copy goes stale silently, while a link and a
command stay honest.

---

## 8. What is not here

`tabbit` is installed at `~/.agents/skills/tabbit` on the reference machine but is **excluded from
this repo**. It carries a `.tabbit-dance-managed` marker: a third-party installer owns it, and
copying or linking it breaks that installer's own update path. Install it separately, the way its
provider documents.

External plugins in `catalog.tsv` are likewise **not** vendored. This repo records where they live
and how to install them; it does not ship their code, and it does not install them for you.

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
