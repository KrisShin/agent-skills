# Retro — the lesson ledger

The ledger is how this setup learns without rewriting itself mid-flight. Two moves: **write the lesson down**, then **decide whether it has repeated enough to become a guardrail**.

Do not skip straight to editing `AGENTS.md` or a skill. A single bad session must not permanently change how every future session behaves.

## 1 — Find the lesson

Look at what actually happened, not what you intended:

- Where did the user have to repeat themselves, correct you, or re-explain context?
- What did you discover by trial and error that was already knowable from the repo?
- Which mistake would an automated check have caught instantly?
- Where did you spend several tool calls on something one pointer would have answered?

Not every session has a lesson. "Nothing recurred" is a valid result — say so and stop.

## 2 — Write it

Append to `.scratch/_lessons.md` (create it from [LESSONS.md](LESSONS.md) if absent). A usable entry has all four:

- **Key** — stable kebab-case. The same recurring lesson must reuse the same key; the count depends on it.
- **Trigger** — the situation that surfaced it, specific enough to recognise again.
- **Rule** — what to do next time, as an action. "Be more careful" is not a rule.
- **Cost** — what it cost, concretely.
- **Severity** — `structural` or `friction`. **Structural** means the process is missing a step: following it faithfully produced the failure, so care alone could not have prevented it. **Friction** means the step exists but is easy to skip or misread. Most lessons are friction; calling everything structural defeats the point.

**Recurrence updates the existing entry, it does not add a new one.** Bump that entry's `Seen`, append today's date to `Dates`. Two entries with the same key is a bug: the count silently under-reports and the lesson never earns promotion.

## 3 — Decide on promotion

A lesson earns **one** proposal when either:

- it is **`Severity: structural`**, on the first sighting — a missing step is a defect in the process, and waiting for it to bite twice costs a second real failure; or
- it has **`seen >= 2`**, whatever its severity — repetition is the evidence that a written rule will not be remembered.

The asymmetry is deliberate: structural lessons are rare and expensive, so they promote at once; friction lessons are common and cheap, so they must prove they recur.

Offer the proposal at the most durable level that can carry it:

1. **An automated check** — lint rule, test, pre-commit hook, CI job. Best: it cannot be forgotten and costs no context. Classify first: a *mechanical* violation (banned API, import shape, file location, fixed syntactic pattern) always gets a check, never a written rule.
2. **A line in `AGENTS.md`** — for a judgement call a check cannot express, and only as a pointer to a longer doc. `AGENTS.md` loads every turn, so every line costs.
3. **A rule in a skill** — when the lesson is about how a discipline is executed rather than about this repo's code.

Propose it in one sentence, with the exact edit you would make. Then **wait**. The user approves, edits, or declines. If you cannot ask a human (you are inside a subagent), follow [Human gates](../SKILL.md#human-gates).

- On yes: make the edit, then note in the lesson entry where it now lives.
- On no: leave it in the ledger and say it stays a note. Do not re-propose it next session unless it recurs again.

A lesson that earns neither — friction, seen once — stays in the ledger and is **not** proposed. That restraint is what keeps the always-loaded context free of sediment.

## 4 — Prune while you are here

If `AGENTS.md` or a skill has grown past what you can hold in your head, look for lines that no longer change behaviour — an instruction the model already follows by default, a rule now enforced by a check, a pointer to something deleted. Propose deleting the whole line, not trimming it. Deleting is the cheap half of learning.
