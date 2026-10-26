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

## Step 3 — Copy, do not symlink

```bash
cp -R ~/agent-skills/{ship,grilling,tdd,diagnosing-bugs} ~/.agents/skills/
```

```powershell
foreach ($d in 'ship','grilling','tdd','diagnosing-bugs') {
  Copy-Item -Recurse -Force "$env:USERPROFILE\agent-skills\$d" "$env:USERPROFILE\.agents\skills\$d"
}
```

Or run `scripts/install.sh` / `scripts/install.ps1`, which also pulls.

**Why not symlink**: if the host has `dsh-ops` (or any file tool that refuses reparse points),
`ops_*` calls against a linked skill directory fail with `PATH_RESTRICTED`. `ship` reads
`references/` at Stages 5 and 6, so a link breaks it exactly where it matters. This was measured,
not assumed. Copying works on every host.

## Step 4 — Verify, in this order

Run all three. They test different things.

**4a. The files landed and are complete.**

```bash
find ~/.agents/skills/ship -name '*.md' | wc -l    # expect 8
```

One `SKILL.md` plus seven under `references/`. Fewer means a partial copy.

**4b. A model-invocable skill actually loads.**

Ask the skill loader for `grilling` and read the body it returns. If it returns the interview
instructions, discovery and loading both work. This is the strongest cheap check.

**4c. `ship` is correctly *not* model-invocable.**

Ask the loader for `ship`. The correct result is an error like "not available for model invocation".
If it loads, the frontmatter lost its `disable-model-invocation: true` line — fix the file, do not
"repair" it by making the skill model-visible.

Do not report success on the strength of `ls`. A directory existing proves nothing about whether the
host scanned it.

## Step 5 — Report

Tell the user, briefly:

- the root you installed into
- the result of 4a, 4b, 4c
- whether a restart is needed on this host

---

## When something fails

| Symptom | Cause | Fix |
| --- | --- | --- |
| Skill never appears in the catalog | Wrong root for this host | Re-read Step 1; check the host's own docs |
| `ops_*` returns `PATH_RESTRICTED` | The skill dir is a symlink/junction | Replace it with a real copy (Step 3) |
| `ship` loads via the model | `disable-model-invocation` missing or misspelled | Restore the line; a rejected boolean drops the whole skill |
| Only `SKILL.md` present, no `references/` | Copied the file, not the directory | Copy the directory |
| Files differ from the repo byte-for-byte | CRLF checkout | Confirm `.gitattributes` is present and re-clone |
| `git pull` fails: no tracking branch | Local clone with no remote | Expected on a fresh local repo; install from the working tree |

Report failures with the exact command and its output. "It didn't work" is not a report.

---

## Do not

- Do not edit files inside `~/.agents/skills` — the installer replaces that directory. Edit the
  repo, then re-run the installer.
- Do not add `tabbit` to a sync. A third-party installer owns it; copying or linking it breaks that
  installer's update path.
- Do not invent a package entry point. There is no build, no `main`, no install hook. If a host asks
  for one, this repo is not shaped for that host.
