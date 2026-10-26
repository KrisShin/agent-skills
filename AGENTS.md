# AGENTS.md — installing these skills on a new host

You are an agent asked to install this repo on a machine. Follow these steps in order. Every
"verify" below is a check you can actually run, not a reassurance.

Read `README.md` for the reasoning; this file is the procedure.

---

## Step 1 — Find where this host reads skills

Do not assume. Resolve it:

- **DSH**: roots are ranked `100 <project>/.dsh/skills`, `200 <project>/.agents/skills`,
  `300 customSkillDirs`, `400 ~/.dsh/skills`, `500 ~/.agents/skills`, `600 bundled`.
  Use `~/.agents/skills` unless the user asks for project scope.
- **Another host**: find its own skill-discovery documentation. If it has no concept of skills,
  stop and tell the user — these files are Markdown instructions for an agent that loads them; they
  are not a package and have no entry point.

Report which root you chose and why, in one line, before writing anything.

## Step 2 — Clone

```bash
git clone https://github.com/KrisShin/agent-skills.git ~/agent-skills
```

The repo is private. If the clone asks for credentials, the user must authenticate first; do not
attempt to work around it.

## Step 3 — Ask which entries to install

`catalog.tsv` lists two kinds of entry: `local` skills shipped here, and `external` plugins hosted
elsewhere. **Ask the user; do not install everything because it is listed.**

Run the installer, which does the detection and the asking for you:

```bash
./scripts/install.sh
```
```powershell
.\scripts\install.ps1
```

It reports what is already installed, prints only the not-yet-installed entries, and asks once
(`1,3` / `all` / Enter to cancel). Local selections are then copied; external selections only print
their repo link and commands.

If you are running without a terminal and cannot answer its prompt, do the same thing by hand:

1. Read `catalog.tsv`.
2. For each `local` row, check `<skillsRoot>/<name>/SKILL.md`.
3. For each `external` row, check that the package is in the host profile's `node_modules` **and**
   listed in `dsh.profile.bundles`.
4. Ask the user which of the **missing** ones to install, then pass those names as arguments:
   `./scripts/install.sh ship tdd`.

Never silently install an entry the user did not choose, and never reinstall one that is already
present.

## Step 4 — Copy, do not symlink

The installer copies. If you are doing it by hand:

```bash
cp -R ~/agent-skills/{ship,grilling,tdd,diagnosing-bugs} ~/.agents/skills/
```

```powershell
foreach ($d in 'ship','grilling','tdd','diagnosing-bugs') {
  Copy-Item -Recurse -Force "$env:USERPROFILE\agent-skills\$d" "$env:USERPROFILE\.agents\skills\$d"
}
```

**Why not symlink**: if the host has `dsh-ops` (or any file tool that refuses reparse points),
`ops_*` calls against a linked skill directory fail with `PATH_RESTRICTED`. `ship` reads
`references/` at Stages 5 and 6, so a link breaks it exactly where it matters. This was measured,
not assumed. Copying works on every host.

## Step 5 — External plugins: print, do not run

For each chosen `external` row, hand the user the upstream link and the exact commands. Do not run
`dsh plugin add` yourself unless the user explicitly asks you to.

```sh
dsh plugin --profile desktop add dsh-ops@0.4.1
```

Tell them the two host facts that bite:

- Quit DeepSeek Harness before installing; the running app owns the `desktop` profile.
- If the host reports an incompatible version, that is the package's peer-range gate. Grant the
  exact-version exemption rather than editing the package:
  ```sh
  dsh plugin --profile desktop allow-version dsh-ops@0.4.1 --dsh-version 0.2.1-rc.3 --accept-risk
  ```

## Step 6 — Verify, in this order

Run all three. They test different things.

**6a. The files landed and are complete.**

```bash
find ~/.agents/skills/ship -name '*.md' | wc -l    # expect 8
```

One `SKILL.md` plus seven under `references/`. Fewer means a partial copy.

**6b. A model-invocable skill actually loads.**

Ask the skill loader for `grilling` and read the body it returns. If it returns the interview
instructions, discovery and loading both work. This is the strongest cheap check.

**6c. `ship` is correctly *not* model-invocable.**

Ask the loader for `ship`. The correct result is an error like "not available for model invocation".
If it loads, the frontmatter lost its `disable-model-invocation: true` line — fix the file, do not
"repair" it by making the skill model-visible.

Do not report success on the strength of `ls`. A directory existing proves nothing about whether the
host scanned it.

## Step 7 — Report

Tell the user, briefly:

- the root you installed into
- which entries were already present and which you installed
- the result of 6a, 6b, 6c
- for external plugins: that you only printed commands, and what remains for them to run
- whether a restart is needed on this host

---

## When something fails

| Symptom | Cause | Fix |
| --- | --- | --- |
| Skill never appears in the catalog | Wrong root for this host | Re-read Step 1; check the host's own docs |
| `ops_*` returns `PATH_RESTRICTED` | The skill dir is a symlink/junction | Replace it with a real copy (Step 4) |
| `ship` loads via the model | `disable-model-invocation` missing or misspelled | Restore the line; a rejected boolean drops the whole skill |
| Only `SKILL.md` present, no `references/` | Copied the file, not the directory | Copy the directory |
| Files differ from the repo byte-for-byte | CRLF checkout | Confirm `.gitattributes` is present and re-clone |
| `git pull` fails: no tracking branch | Local clone with no remote | Expected; install from the working tree |
| `git pull` fails: unstaged changes | You edited a skill before re-running | Expected; the installer warns and uses the working tree |
| Everything reported "already installed" but the skill is absent | The install check looks at the file, not the host | Check the root from Step 1 |

Report failures with the exact command and its output. "It didn't work" is not a report.

---

## Do not

- Do not install every catalog entry just because it is listed. Ask (Step 3).
- Do not install an `external` entry's package for the user unless they ask. Print the command.
- Do not edit files inside `~/.agents/skills` — the installer replaces that directory. Edit the
  repo, then re-run the installer.
- Do not add `tabbit` to a sync. A third-party installer owns it; copying or linking it breaks that
  installer's update path.
- Do not vendor an external plugin into this repo. Record the link and the verified spec instead.
- Do not invent a package entry point. There is no build, no `main`, no install hook. If a host asks
  for one, this repo is not shaped for that host.
